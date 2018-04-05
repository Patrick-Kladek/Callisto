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

    init?(contentsOfFile url: URL, branch: String, account: GithubAccount, organisation: String, repository: String, slack: URL, ignoredKeywords: [String]) {
        self.currentBranch = Branch()
        self.currentBranch.name = branch
        self.gitAccount = account
        self.githubController = GitHubCommunicationController(account: account, organisation: organisation, repository: repository)
        self.slackController = SlackCommunicationController(url: slack)
        self.ignore = ignoredKeywords

        guard let parser = FastlaneParser(url: url, ignoredKeywords: ignoredKeywords) else { return nil }
        self.parser = parser
    }

    func run() -> Status {
        let fastlaneParserStatus = self.parser.parse()

        if case .error = fastlaneParserStatus {
            // Status code was unavailible but App should work fine
            LogError("Error parsing status code from fastlane.")
        }

        if self.reloadCurrentBranch() == false {
            LogWarning("Loading of branch failed, contiune without corrent branch name")
        }

        if self.parser.staticAnalyzerMessages.isEmpty == false {
            let slackMessage = self.makeSlackMessage(title: self.currentBranch.title, url: self.currentBranch.url)
            guard let data = slackMessage.jsonDataRepresentation() else { return .warning(code: ExitCodes.jsonConversationFailed.rawValue) }
            self.slackController.post(data: data)
        }

        self.logCompilerMessages(self.parser.staticAnalyzerMessages)
        self.logCompilerMessages(self.parser.buildErrorMessages)
        self.logUnitTestMessage(self.parser.unitTestMessages)

        var warningCount = 0

        if case .success(let code) = fastlaneParserStatus {
            LogWarning("Fastlane exit code: \(code)")
            warningCount += code
        }

        LogMessage("--------------------- Summary ---------------------")
        LogMessage("Ignored Keywords: \(self.ignore.joined(separator: ", "))")
        if self.parser.buildErrorMessages.isEmpty == false {
            LogError("\(self.parser.buildErrorMessages.count). Build Errors")
        }
        if self.parser.staticAnalyzerMessages.isEmpty == false {
            LogError("\(self.parser.staticAnalyzerMessages.count). Static Analyzer Warnings")
        }
        if self.parser.unitTestMessages.isEmpty == false {
            LogError("\(self.parser.unitTestMessages.count). Unit Test Errors")
        }

        warningCount += self.parser.buildErrorMessages.count
        warningCount += self.parser.unitTestMessages.count

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

        for compilerMessage in self.parser.staticAnalyzerMessages {
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
