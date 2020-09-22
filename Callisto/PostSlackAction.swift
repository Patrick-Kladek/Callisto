//
//  PostSlackAction.swift
//  Callisto
//
//  Created by Patrick Kladek on 22.09.20.
//  Copyright © 2020 IdeasOnCanvas. All rights reserved.
//

import Foundation


/// Responsible to post the parsed build information to Slack
final class PostSlackAction: NSObject {

    private lazy var ignore: [String] = {
        return self.defaults.ignoredKeywords
    }()

    let defaults: UserDefaults
    let slackController: SlackCommunicationController
    let githubController: GitHubCommunicationController

    // MARK: - Lifecycle

    init(defaults: UserDefaults) {
        self.defaults = defaults
        self.slackController = SlackCommunicationController(url: defaults.slackURL)
        self.githubController = GitHubCommunicationController(account: defaults.githubAccount,
                                                              repository: defaults.githubRepository)
    }

    // MARK: - PostSlackAction

    func run() -> Never {
        let inputFiles = CommandLine.parameters(forKey: "files").map { URL(fileURLWithPath: $0) }
        guard inputFiles.count > 0 else { quit(.invalidBuildInformationFile) }

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

    func currentBranch() -> Branch {
        switch self.githubController.branch(named: defaults.branch) {
        case .success(let branch):
            return branch
        case .failure(let error):
            LogError(error.localizedDescription)
            quit(.reloadBranchFailed)
        }
    }

    func makeSlackMessage(for branch: Branch, infos: [BuildInformation]) -> SlackMessage {
        let message = SlackMessage()

        // Overview
        let overViewAttachment = SlackAttachment(type: .good)
        overViewAttachment.title = branch.title
        overViewAttachment.titleURL = branch.url
        overViewAttachment.footer = "Ignored: \(self.ignore.joined(separator: ", "))"
        message.add(attachment: overViewAttachment)

        // Errors
        let errorAttachments = SlackAttachment(type: .danger)
        let errors = infos.flatMap { $0.errors }
        for compilerMessage in errors {
            if self.ignore.contains(where: { compilerMessage.description.contains($0)}) { continue }

            errorAttachments.addField(SlackField(message: compilerMessage))
        }
        message.add(attachment: errorAttachments)

        // Warnings
        let warningAttachments = SlackAttachment(type: .warning)
        let warnings = infos.flatMap{ $0.warnings }
        for compilerMessage in warnings {
            if self.ignore.contains(where: { compilerMessage.description.contains($0)}) { continue }

            warningAttachments.addField(SlackField(message: compilerMessage))
        }
        message.add(attachment: warningAttachments)

        // Unit Tests
        let unitTestAttachments = SlackAttachment(type: .danger)
        unitTestAttachments.colorHex = "blue"
        let unitTests = infos.flatMap { $0.unitTests }
        for compilerMessage in unitTests {
            if self.ignore.contains(where: { compilerMessage.description.contains($0)}) { continue }

            unitTestAttachments.addField(SlackField(message: compilerMessage))
        }
        message.add(attachment: unitTestAttachments)
        return message
    }
}
