//
//  UploadAction.swift
//  Callisto
//
//  Created by Patrick Kladek on 02.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


/// Responsible to read the build summaries and post them to github
final class UploadAction: NSObject {

    let defaults: UserDefaults

    // MARK: - Properties

    // MARK: - Lifecycle
	
    init(defaults: UserDefaults) {
        self.defaults = defaults
	}

    // MARK: - UploadAction

    func run() -> Never {
        var inputFiles = CommandLine.parameters(forKey: "files")


        let url = defaults.fastlaneOutputURL
        let branch = defaults.branch
        let githubAccount = defaults.githubAccount
        let githubRepository = defaults.githubRepository
        let slackURL = defaults.slackURL
        let ignoredKeywords = defaults.ignoredKeywords



        guard let controller = MainController(contentsOfFile: url, branch: branch, account: githubAccount, repository: githubRepository, slack: slackURL, ignoredKeywords: ignoredKeywords) else { quit(.internalError) }

        switch controller.run() {

        case .success(let warningCount) where warningCount > 0:
            // Limit count because exit func only display 8 bit -> 256 mean 0 which will say everything is ok while it´s not.
            // also use 200 so it will not conflict with above return values.
            LogError("Static Analyzer failed")
            exit(min(200, warningCount))
        case .warning(code: let code):
            LogWarning("Posting to Slack Failed \(code)")
            LogMessage("Static Analyzer Successful. No Warnings found")
            quit(.success)
        default:
            LogMessage("Static Analyzer Successful. No Warnings found")
            quit(.success)
        }
    }
}

extension CommandLine {

    static func parameters(forKey key: String) -> [String] {
        var inputFiles: [String] = []
        for i in 0...CommandLine.arguments.count - 1 {
            if CommandLine.arguments[i] == "-\(key)" {
                for j in (i + 1)...(CommandLine.arguments.count - i - 1) {
                    let argument = CommandLine.arguments[j]
                    if argument.first == "-" { break }
                    inputFiles.append(argument)
                }
            }
        }
        return inputFiles
    }
}

// MARK: - Private

private extension UploadAction {

    
}

// MARK: - Strings

private extension UploadAction {

    enum Strings {
    	
    }
}
