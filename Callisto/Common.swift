//
//  Common.swift
//  Callisto
//
//  Created by Patrick Kladek on 12.01.18.
//  Copyright © 2018 IdeasOnCanvas. All rights reserved.
//

import Foundation

enum ExitCodes: Int32 {
    case invalidFile = -1
    case invalidBranch = -2
    case invalidGithubUsername = -3
    case invalidGithubCredentials = -4
    case invalidGithubOrganisation = -5
    case invalidGithubRepository = -6
    case invalidSlackWebhook = -7
    case parsingFailed = -10
    case reloadBranchFailed = -11
    case jsonConversationFailed = -12
    case fastlaneFinishedWithErrors = -13
}

struct AppInfo {
    static let version = "1.0"
    static let build = 2
}

func time() -> String {
    return DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
}

func LogError(_ message: String) {
    print("\(time()) [\u{001B}[0;31m ERROR \u{001B}[0;0m] \(message)")
}

func LogWarning(_ message: String) {
    print("\(time()) [\u{001B}[0;33mWARNING\u{001B}[0;0m] \(message)")
}

func LogMessage(_ message: String) {
    print("\(time()) [\u{001B}[0;32mMESSAGE\u{001B}[0;0m] \(message)")
}
