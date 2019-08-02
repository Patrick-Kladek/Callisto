//
//  main.swift
//  clangParser
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation
import Cocoa
import Darwin // we need Darwin for exit() function


extension UserDefaults {

    enum Action {
        case summarize
        case upload
        case unknown
    }

    var action: Action {
        switch self.string(forKey: "action") {
        case "summarize":
            return .summarize
        case "upload":
            return .upload
        default:
            LogError("No action specified")
            exit(ExitCodes.invalidAction.rawValue)
        }
    }

    var fastlaneOutputURL: URL {
        return self.url(forKey: "fastlane") ?? { quit(.invalidFile) }()
    }

    var branch: String {
        return self.string(forKey: "branch") ?? { quit(.invalidBranch) }()
    }

    var githubAccount: GithubAccount {
        let username = self.string(forKey: "githubUsername") ?? { quit(.invalidGithubUsername) }()
        let token = self.string(forKey: "githubToken") ?? { quit(.invalidGithubCredentials) }()
        return GithubAccount(username: username, token: token)
    }

    var githubRepository: GithubRepository {
        let organisation = self.string(forKey: "githubOrganisation") ?? { quit(.invalidGithubOrganisation) }()
        let repository = self.string(forKey: "githubRepository") ?? { quit(.invalidGithubRepository) }()
        return GithubRepository(organisation: organisation, repository: repository)
    }

    var slackURL: URL {
        let slackPath = self.string(forKey: "slack") ?? { quit(.invalidSlackWebhook) }()
        return URL(string: slackPath) ?? { quit(.invalidSlackWebhook) }()
    }

    var ignoredKeywords: [String] {
        return self.string(forKey: "ignore")?.components(separatedBy: ", ") ?? []
    }
}


func main() {
    let defaults = UserDefaults.standard

    if (CommandLine.arguments.contains("-help") || CommandLine.arguments.contains("-info")) {
        LogMessage("Callisto \(AppInfo.version))")
        exit(0)
    }

    let url = defaults.fastlaneOutputURL
    let branch = defaults.branch
    let githubAccount = defaults.githubAccount
    let githubRepository = defaults.githubRepository
    let slackURL = defaults.slackURL
    let ignoredKeywords = defaults.ignoredKeywords

    switch defaults.action {
    case .summarize:
        guard let extractController = ExtractBuildInformationController(contentsOfFile: url, ignoredKeywords: ignoredKeywords) else { exit(ExitCodes.internalError.rawValue) }

        switch extractController.run() {
        case .success:
            let tempURL = URL.tempURL(extractController.buildInfo.platform)
            let result = extractController.save(to: tempURL)
            switch result {
            case .success:
                print("Succesfully saved summarized output at: \(tempURL)")
                exit(0)
            case .failure(let error):
                LogError("Saving summary failed: \(error)")
                exit(ExitCodes.savingFailed.rawValue)
            }

        case .failure:
            LogError("Parsing of fastlane output failed")
            exit(ExitCodes.parsingFailed.rawValue)
        }

    default:
        break
    }


    guard let controller = MainController(contentsOfFile: url, branch: branch, account: githubAccount, repository: githubRepository, slack: slackURL, ignoredKeywords: ignoredKeywords) else { exit(-8) }

    switch controller.run() {
    case .success(let warningCount) where warningCount > 0:
        // Limit count because exit func only display 8 bit -> 256 mean 0 which will say everything is ok while it´s not.
        // also use 200 so it will not conflict with above return values.
        LogError("Static Analyzer failed")
        exit(min(200, warningCount))
    case .warning(code: let code):
        LogWarning("Posting to Slack Failed \(code)")
        LogMessage("Static Analyzer Successful. No Warnings found")
        exit(0)
    default:
        LogMessage("Static Analyzer Successful. No Warnings found")
        exit(0)
    }
}

main()

