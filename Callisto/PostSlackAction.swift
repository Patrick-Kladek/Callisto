//
//  PostSlackAction.swift
//  Callisto
//
//  Created by Patrick Kladek on 22.09.20.
//  Copyright © 2020 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser


final class PostToSlack: ParsableCommand {

    public static let configuration = CommandConfiguration(commandName: "slack", abstract: "Post Build Summary to Slack")

    @Argument(help: "Location for .buildReport file", completion: .file(), transform: URL.init(fileURLWithPath:))
    var files: [URL]

    @Option(help: "URL access Slack", transform: { return URL(string: $0)! })
    var slackUrl: URL

    @Option(help: "Token to access github")
    var githubToken: String

    @Option(help: "Organisation Account Name in github")
    var githubOrganisation: String

    @Option(help: "Github Repository Name")
    var githubRepository: String

    @Option(help: "Github Branch")
    var branch: String

    // MARK: - ParsableCommand

    func run() throws {
        let action = PostSlackAction(command: self)
        try action.run()
    }
}

/// Responsible to post the parsed build information to Slack
final class PostSlackAction: NSObject {

    let command: PostToSlack
    let slackController: SlackCommunicationController
    let githubController: GitHubCommunicationController

    // MARK: - Lifecycle

    init(command: PostToSlack) {
        self.command = command
        let repo = GithubRepository(organisation: command.githubOrganisation, repository: command.githubRepository)
        let access = GithubAccess(token: command.githubToken)
        self.githubController = GitHubCommunicationController(access: access, repository: repo)
        self.slackController = SlackCommunicationController(url: command.slackUrl)
    }

    // MARK: - PostSlackAction

    func run() throws {
        let inputFiles = self.command.files
        guard inputFiles.hasElements else { quit(.invalidBuildInformationFile) }

        let infos = inputFiles.map { BuildInformation.read(url: $0) }.compactMap { result -> BuildInformation? in
            switch result {
            case .success(let info):
                return info
            case .failure(let error):
                LogError("\(error)")
                return nil
            }
        }

        if infos.allSatisfy({ $0.isEmpty }) {
            LogMessage("No Build issues found")
            quit(.success)
        }

        let branch = self.currentBranch()
        let slackMessage = self.makeSlackMessage(for: branch, infos: infos)
        guard let data = slackMessage.jsonDataRepresentation() else { quit(.jsonConversationFailed) }

        self.slackController.post(data: data)
        quit(.success)
    }
}

// MARK: - Private

private extension PostSlackAction {

    func currentBranch() -> Branch? {
        switch self.githubController.branch(named: self.command.branch) {
        case .success(let branch):
            return branch
        case .failure(let error):
            LogWarning(error.localizedDescription)
            return nil
        }
    }

    func makeSlackMessage(for branch: Branch?, infos: [BuildInformation]) -> SlackMessage {
        let ignoredKeywords = infos.flatMap { $0.ignoredKeywords }
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
}
