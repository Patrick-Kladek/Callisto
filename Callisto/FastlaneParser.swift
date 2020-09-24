//
//  FastlaneParser.swift
//  clangParser
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa


enum ParserError: Error {
    case exitStatusNotFound
    case fastlaneRunError
}

enum FastlaneRunStatus {
    case success
    case failure(exitCode: Int)
    case unknown
}

class FastlaneParser {

    private let content: String
    private let ignoredKeywords: [String]
    private(set) var buildSummary: BuildInformation = .empty
    private(set) var fastlaneReturnValue: FastlaneRunStatus = .unknown

    init(content: String, ignoredKeywords: [String]) {
        self.content = content
        self.ignoredKeywords = ignoredKeywords
    }

    convenience init(url: URL, ignoredKeywords: [String]) throws {
        let content = try String(contentsOf: url)
        self.init(content: content, ignoredKeywords: ignoredKeywords)
    }

    func parse() -> Int {
        let trimmedContent = self.trimColors(in: self.content)
        let lines = trimmedContent.components(separatedBy: .newlines)

        self.buildSummary = BuildInformation(platform: self.parseSchemeFromFastlane(trimmedContent) ?? "",
                                             errors: self.parseBuildErrors(lines),
                                             warnings: self.parseAnalyzerWarnings(lines),
                                             unitTests: self.parseUnitTestWarnings(lines))

        return self.parseExitStatusFromFastlane(trimmedContent)
    }
}

fileprivate extension FastlaneParser {

    func parseSchemeFromFastlane(_ content: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "\\| scheme[ ]*\\| [a-zA-Z ]*\\|\\n", options: .caseInsensitive) else {
            print("Regular Expression Failed");
            return nil
        }

        let schemeLineRange = regex.rangeOfFirstMatch(in: content, options: .reportCompletion, range: NSMakeRange(0, content.count))
        guard var schemeLine = content.substring(with: schemeLineRange)?.removeExtraSpaces() else {
            return nil
        }

        schemeLine = schemeLine.replacingOccurrences(of: "| scheme | ", with: "")
        schemeLine = schemeLine.replacingOccurrences(of: " | ", with: "")
        return schemeLine
    }

    func parseBuildErrors(_ lines: [String]) -> [CompilerMessage] {
        let errorLines = lines.filter { self.lineIsError($0) }
        return self.compilerMessages(from: errorLines)
    }

    func parseAnalyzerWarnings(_ lines: [String]) -> [CompilerMessage] {
        let warningLines = lines.filter { self.lineIsWarning($0) }
        return self.compilerMessages(from: warningLines)
    }

    func parseUnitTestWarnings(_ lines: [String]) -> [UnitTestMessage] {
        let unitTestLines = lines.filter { self.lineIsUnitTest($0) }

        let filteredLines = Set(unitTestLines.compactMap { line -> UnitTestMessage? in
            for keyword in self.ignoredKeywords {
                guard line.lowercased().contains(keyword) == false else { return nil }
            }

            return UnitTestMessage(message: line)
        })

        return Array(filteredLines)
    }

    func parseExitStatusFromFastlane(_ content: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: "\\[[0-9]+:[0-9]+:[0-9]+]: Exit status: [0-9]+", options: .caseInsensitive) else {
            print("Regular Expression Failed");
            return 0
        }

        let exitStatusLineRange = regex.rangeOfFirstMatch(in: content, options: .reportCompletion, range: NSMakeRange(0, content.count))
        guard let exitStatusLine = content.substring(with: exitStatusLineRange) else {
            // No exit status found means we`re ok
            return 0
        }

        guard let regexStatus = try? NSRegularExpression(pattern: "\\[[0-9]+:[0-9]+:[0-9]+]: Exit status: ", options: .caseInsensitive) else {
            LogWarning("Regular Expression Failed")
            return 0
        }

        let statusCodeString = regexStatus.stringByReplacingMatches(in: exitStatusLine, options: [], range: NSMakeRange(0, exitStatusLine.count), withTemplate: "")
        let statusCode = Int(statusCodeString) ?? 0
        return statusCode
    }

    func parseExitedWithError(_ content: String) -> Result<Int, ParserError> {
        if content.contains("fastlane finished with errors") {
            LogError("Fastlane finished with errors")
            return .failure(.fastlaneRunError)
        }

        return .success(-1)
    }
}

private extension FastlaneParser {

    func lineIsWarning(_ line: String) -> Bool {
        let pattern = "⚠️"
        return self.check(line: line, withRegex: pattern)
    }

    func lineIsError(_ line: String) -> Bool {
        let pattern = "❌"
        return self.check(line: line, withRegex: pattern)
    }

    func lineIsUnitTest(_ line: String) -> Bool {
        let pattern = "✗"
        return self.check(line: line, withRegex: pattern)
    }

    func trimColors(in input: String) -> String {
        var filteredString = input
        filteredString = filteredString.replacingOccurrences(of: "\r", with: "")
        filteredString = filteredString.replacingOccurrences(of: "\u{1b}", with: "")

        guard let regex = try? NSRegularExpression(pattern: "\\[[0-9]+(m|;)[0-9]*(;)*[0-9]*m?", options: .caseInsensitive) else { print("Regular Expression Failed"); return "" }
        let range = NSMakeRange(0, filteredString.count)
        return regex.stringByReplacingMatches(in: filteredString, options: [], range: range, withTemplate: "")
    }

    func compilerMessages(from: [String]) -> [CompilerMessage] {
        let filteredLines = Set(from.compactMap { line -> CompilerMessage? in
            for keyword in self.ignoredKeywords {
                guard line.lowercased().contains(keyword.lowercased()) == false else { return nil }
            }

            return CompilerMessage(message: line)
        })

        return Array(filteredLines)
    }

    func check(line: String, withRegex pattern: String) -> Bool {
        let regex: NSRegularExpression

        do {
            try regex = NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch {
            print("error: could not create Regex")
            return false
        }

        let range = NSMakeRange(0, line.count)
        let matches = regex.matches(in: line, options: .reportCompletion, range: range)
        return matches.count > 0
    }
}

private extension String {

    func removeExtraSpaces() -> String {
        return self.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
    }

}
