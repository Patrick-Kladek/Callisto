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



func main() {
    let defaults = UserDefaults.standard

    if (CommandLine.arguments.contains("-help") || CommandLine.arguments.contains("-info")) {
        LogMessage("Callisto \(AppInfo.version))")
        exit(0)
    }

    guard let action = defaults.string(forKey: "action") else {
        LogError("No action specified")
        exit(ExitCodes.invalidAction.rawValue)
    }

    guard let url = defaults.url(forKey: "fastlane") else {
        LogError("invalid file. Usage -fastfile \"/path/to/file\"")
        exit(ExitCodes.invalidFile.rawValue)
    }

    guard let branch = defaults.string(forKey: "branch") else {
        LogWarning("invalid Branch")
        exit(ExitCodes.invalidBranch.rawValue)
    }

    guard let githubUsername = defaults.string(forKey: "githubUsername") else {
        LogError("invalid Github username. Usage: -githubUsername \"username\"")
        exit(ExitCodes.invalidGithubUsername.rawValue)
    }

    guard let githubToken = defaults.string(forKey: "githubToken") else {
        LogError("invalid Github credentials. Usage either: -githubToken \"token\"")
        exit(ExitCodes.invalidGithubCredentials.rawValue)
    }

    guard let githubOrganisation = defaults.string(forKey: "githubOrganisation") else {
        LogError("invalid Github Organisation. Usage -githubOrganisation \"organisation\"")
        exit(ExitCodes.invalidGithubOrganisation.rawValue)
    }

    guard let githubRepository = defaults.string(forKey: "githubRepository") else {
        LogError("invalid Github Repository. Usage -githubRepository \"repository\"")
        exit(ExitCodes.invalidGithubRepository.rawValue)
    }

    guard let slackPath = defaults.string(forKey: "slack"), let slackURL = URL(string: slackPath) else {
        LogError("invalid Slack Webhook URL. Usage -slack \"slackURL\"")
        exit(ExitCodes.invalidSlackWebhook.rawValue)
    }

    let ignoredKeywords = defaults.string(forKey: "ignore")?.components(separatedBy: ", ") ?? []

    switch action {
    case "summarize":
        guard let extractController = ExtractBuildInformationController(contentsOfFile: url, ignoredKeywords: ignoredKeywords) else { exit(-8) }

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


    let account = GithubAccount(username: githubUsername, token: githubToken)
    guard let controller = MainController(contentsOfFile: url, branch: branch, account: account, organisation: githubOrganisation, repository: githubRepository, slack: slackURL, ignoredKeywords: ignoredKeywords) else { exit(-8) }

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

