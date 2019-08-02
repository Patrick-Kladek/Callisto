//
//  MainController.swift
//  clangParser
//
//  Created by Patrick Kladek on 20.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

enum Status {
    case success(warningCount: Int32)
    case warning(code: Int32)
    case error(code: Int32)
}

class MainController {

    public fileprivate(set) var gitAccount: GithubAccount
    public fileprivate(set) var currentBranch: Branch

    fileprivate var parser: FastlaneParser
    fileprivate var githubController: GitHubCommunicationController
    fileprivate var slackController: SlackCommunicationController
    fileprivate var ignore: [String]

    init?(contentsOfFile url: URL, branch: String, account: GithubAccount, repository: GithubRepository, slack: URL, ignoredKeywords: [String]) {
        self.currentBranch = Branch(name: branch)
        self.gitAccount = account
        self.githubController = GitHubCommunicationController(account: account, repository: repository)
        self.slackController = SlackCommunicationController(url: slack)
        self.ignore = ignoredKeywords

        guard let parser = FastlaneParser(url: url, ignoredKeywords: ignoredKeywords) else { return nil }
        self.parser = parser
    }

    func run() -> Status {
        var warningCount = 0
        let fastlaneParserStatus = self.parser.parse()

        if fastlaneParserStatus > 0 {
            // Fastlane finished with error
            LogError("Error running fastlane. Exit code: \(fastlaneParserStatus)")
            warningCount += fastlaneParserStatus
        }

        if self.reloadCurrentBranch() == false {
            LogWarning("Loading of branch failed, contiune without corrent branch name")
        }

        if self.parser.buildSummary.warnings.isEmpty == false {
            let slackMessage = self.makeSlackMessage(title: self.currentBranch.title, url: self.currentBranch.url)
            guard let data = slackMessage.jsonDataRepresentation() else { return .warning(code: ExitCodes.jsonConversationFailed.rawValue) }
//            self.slackController.post(data: data)
        }

        self.logCompilerMessages(self.parser.buildSummary.warnings)
        self.logCompilerMessages(self.parser.buildSummary.errors)
        self.logUnitTestMessage(self.parser.buildSummary.unitTests)

        LogMessage("--------------------- Summary ---------------------")
        LogMessage("Ignored Keywords: \(self.ignore.joined(separator: ", "))")
        if self.parser.buildSummary.errors.isEmpty == false {
            LogError("\(self.parser.buildSummary.errors.count). Build Errors")
        }
        if self.parser.buildSummary.warnings.isEmpty == false {
            LogWarning("\(self.parser.buildSummary.warnings.count). Static Analyzer Warnings")
        }
        if self.parser.buildSummary.unitTests.isEmpty == false {
            LogError("\(self.parser.buildSummary.unitTests.count). Unit Test Errors")
        }

        warningCount += self.parser.buildSummary.errors.count
        warningCount += self.parser.buildSummary.unitTests.count

        return .success(warningCount: Int32(warningCount))
    }
}

fileprivate extension MainController {

    func reloadCurrentBranch() -> Bool {
        guard let name = self.currentBranch.name else { return false }

        do {
            let dict: [String: Any]
            try dict = self.githubController.pullRequest(forBranch: name)
            guard let branchPath = dict["html_url"] as? String, let title = dict["title"] as? String else { throw GithubError.pullRequestNoURL }

            self.currentBranch.title = title
            self.currentBranch.url = URL(string: branchPath)
        } catch GithubError.pullRequestNotAvailible {
            LogError("Pull Request not availible")
            return false
        } catch GithubError.pullRequestNoURL {
            LogWarning("Pull Request URL not availible")
            return true
        } catch {
            LogError("Something happend when collecting information about Pull Requests")
            return false
        }

        return true
    }

    func makeSlackMessage(title: String?, url: URL?) -> SlackMessage {
        let message = SlackMessage()
        let attachment = SlackAttachment(type: .danger)

        attachment.title = title
        attachment.titleURL = url
        attachment.footer = "Ignored: \(self.ignore.joined(separator: ", "))"

        for compilerMessage in self.parser.buildSummary.warnings {
            attachment.addField(SlackField(message: compilerMessage))
        }

        message.add(attachment: attachment)
        return message
    }

    func logCompilerMessages(_ messages: [CompilerMessage]) {
        for message in messages {
            LogMessage(message.description)
        }
    }

    func logUnitTestMessage(_ messages: [UnitTestMessage]) {
        for message in messages {
            LogMessage(message.description)
        }
    }
}
