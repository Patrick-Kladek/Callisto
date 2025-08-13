//
//  PostSlackCommand.swift
//  Callisto
//
//  Created by Patrick Kladek on 22.09.20.
//  Copyright © 2020 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser
import SlackKit
import GithubKit
import Common

final class PostSlackCommand: AsyncParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "slack",
        abstract: "Post Build Summary to Slack"
    )

    @Argument(help: "Location for .buildReport file", completion: .file())
    var files: [URL]

    @Option(help: "URL access Slack", transform: { return URL(string: $0)! })
    var slackUrl: URL

    @Option(help: "Your GitHub Access Token")
    var githubToken: String

    @Option(help: "Your GitHub Organisation Account Name")
    var githubOrganisation: String

    @Option(help: "Github Repository Name")
    var githubRepository: String

    @Option(help: "Github Branch")
    var branch: String

    // MARK: - ParsableCommand

    func run() async throws {
        let action = PostSlackAction(command: self)
        try await action.run()
    }
}

/// Responsible to post the parsed build information to Slack
final class PostSlackAction: NSObject {

    let command: PostSlackCommand
    let slackController: SlackCommunicationController
    let githubController: GitHubCommunicationController

    // MARK: - Lifecycle

    init(command: PostSlackCommand) {
        self.command = command
        let repo = GithubRepository(organisation: command.githubOrganisation, repository: command.githubRepository)
        let access = GithubAccess(token: command.githubToken)
        self.githubController = GitHubCommunicationController(access: access, repository: repo)
        self.slackController = SlackCommunicationController(url: command.slackUrl)
    }

    // MARK: - PostSlackAction

    func run() async throws {
        let inputFiles = self.command.files
        guard inputFiles.hasElements else { quit(.invalidBuildInformationFile) }

        log("Input Files: ")
        _ = inputFiles.map { log($0.absoluteString) }

        let summaries = inputFiles.map { SummaryFile.read(url: $0) }.compactMap { result -> SummaryFile? in
            switch result {
            case .success(let info):
                return info
            case .failure(let error):
                log("\(error)", level: .error)
                return nil
            }
        }

        let infos = summaries.compactMap { file -> BuildInformation? in
            switch file {
            case .build(let info):
                return info
            default:
                return nil
            }
        }

        let dependencies = summaries.compactMap { file -> DependencyInformation? in
            switch file {
            case .dependencies(let info):
                return info
            default:
                return nil
            }
        }

        if infos.allSatisfy({ $0.isEmpty }) {
            log("No Build issues found")
            quit(.success)
        }

        let branch = await self.currentBranch()
        let slackMessage = self.makeSlackMessage(for: branch, infos: infos, dependencies: dependencies)
        guard let data = slackMessage.jsonDataRepresentation() else { quit(.jsonConversationFailed) }

        try await self.slackController.post(data: data)
        quit(.success)
    }
}

// MARK: - Private

private extension PostSlackAction {

    func currentBranch() async -> Branch? {
        switch await self.githubController.branch(named: self.command.branch) {
        case .success(let branch):
            return branch
        case .failure(let error):
            log(error.localizedDescription, level: .warning)
            return nil
        }
    }

    func makeSlackMessage(for branch: Branch?, infos: [BuildInformation], dependencies: [DependencyInformation]) -> SlackMessage {
        let ignoredKeywords = infos.flatMap {
            [
                $0.config.ignore.values.compactMap { $0.warnings},
                $0.config.ignore.values.compactMap { $0.errors },
                $0.config.ignore.values.compactMap { $0.tests }
            ].flatMap { $0 }
        }.flatMap { $0 }
        let message = SlackMessage()

        // Overview
        let overViewAttachment = SlackAttachment(type: .good)
        overViewAttachment.title = branch?.slackTitle ?? "Branch: \(self.command.branch)"
        overViewAttachment.titleURL = branch?.url
        overViewAttachment.footer = "Ignored: \(ignoredKeywords.joined(separator: ", "))"
        message.add(attachment: overViewAttachment)

        // Errors
        let errors = infos.flatMap { $0.errors }
        message.add(attachment: self.makeSlackAttachment(errors))

        // Warnings
        let warnings = infos.flatMap { $0.warnings }
        message.add(attachment: self.makeSlackAttachment(warnings, type: .warning))

        // Unit Tests
        let unitTests = infos.flatMap { $0.unitTests }
        let unitTestAttachment = self.makeSlackAttachment(unitTests, type: .warning)
        unitTestAttachment.colorHex = "0077FF"
        message.add(attachment: unitTestAttachment)

        // Dependencies
        let outdated = dependencies.flatMap { $0.outdated }
        let dependencyAttachment = self.makeSlackAttachment(outdated, type: .warning)
        message.add(attachment: dependencyAttachment)

        return message
    }

    func makeSlackAttachment(_ messages: [CompilerMessage], type: SlackAttachmentType = .danger) -> SlackAttachment {
        let attachment = SlackAttachment(type: type)
        for message in messages {
            attachment.addField(SlackField(message: message))
        }

        return attachment
    }

    func makeSlackAttachment(_ messages: [UnitTestMessage], type: SlackAttachmentType = .danger) -> SlackAttachment {
        let attachment = SlackAttachment(type: type)
        for message in messages {
            attachment.addField(SlackField(message: message))
        }
        return attachment
    }

    func makeSlackAttachment(_ messages: [Dependency], type: SlackAttachmentType = .danger) -> SlackAttachment {
        let attachment = SlackAttachment(type: type)
        for message in messages {
            attachment.addField(SlackField(title: "\(message.name) \(message.currentVersion.description)",
                                           value: "New Version available: \(message.upgradeableVersion.description)"))
        }
        return attachment
    }
}
