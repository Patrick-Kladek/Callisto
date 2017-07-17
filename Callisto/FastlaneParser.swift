//
//  FastlaneParser.swift
//  clangParser
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

enum FastlaneParserStatus {
    case success(exitCode: Int)
    case error()
}

class FastlaneParser {

    fileprivate let content: String
    fileprivate let ignoredKeywords: [String]
    private(set) var staticAnalyzerMessages: [CompilerMessage] = []
    private(set) var unitTestMessages: [UnitTestMessage] = []
    private(set) var buildErrorMessages: [CompilerMessage] = []

    init(content: String, ignoredKeywords: [String]) {
        self.content = content
        self.ignoredKeywords = ignoredKeywords
    }

    convenience init?(url: URL, ignoredKeywords: [String]) {
        guard let content = try? String(contentsOf: url) else { return nil }
        self.init(content: content, ignoredKeywords: ignoredKeywords)
    }

    func parse() -> FastlaneParserStatus {
        let trimmedContent = self.trimColors(in: self.content)
        let lines = trimmedContent.components(separatedBy: .newlines)

        self.buildErrorMessages.append(contentsOf: self.parseBuildErrors(lines))
        self.staticAnalyzerMessages.append(contentsOf: self.parseAnalyzerWarnings(lines))
        self.unitTestMessages.append(contentsOf: self.parseUnitTestWarnings(lines))

        return self.parseExitStatusFromFastlane(trimmedContent)
    }
}

fileprivate extension FastlaneParser {

    func parseBuildErrors(_ lines: [String]) -> [CompilerMessage] {
        let errorLines = lines.filter { self.lineIsError($0) }
        return self.compilerMessages(from: errorLines)
    }

    func parseAnalyzerWarnings(_ lines: [String]) -> [CompilerMessage] {
        let warningLines = lines.filter { self.lineIsAnalyser($0) }
        return self.compilerMessages(from: warningLines)
    }

    func parseUnitTestWarnings(_ lines: [String]) -> [UnitTestMessage] {
        let unitTestLines = lines.filter { self.lineIsUnitTest($0) }

        let filteredLines = Set(unitTestLines.flatMap { line -> UnitTestMessage? in
            for keyword in self.ignoredKeywords {
                guard line.lowercased().contains(keyword) == false else { return nil }
            }

            return UnitTestMessage(message: line)
        })

        return Array(filteredLines)
    }

    func parseExitStatusFromFastlane(_ content: String) -> FastlaneParserStatus {
        guard let regex = try? NSRegularExpression(pattern: "\\[[0-9]+:[0-9]+:[0-9]+]: Exit status: [0-9]+", options: .caseInsensitive) else {
            print("Regular Expression Failed");
            return FastlaneParserStatus.error()
        }

        let exitStatusLineRange = regex.rangeOfFirstMatch(in: content, options: .reportCompletion, range: NSMakeRange(0, content.characters.count))
        guard let exitStatusLine = content.substring(with: exitStatusLineRange) else {
            // No exit status found means we`re ok
            return FastlaneParserStatus.success(exitCode: -1)
        }

        guard let regexStatus = try? NSRegularExpression(pattern: "\\[[0-9]+:[0-9]+:[0-9]+]: Exit status: ", options: .caseInsensitive) else {
            print("Regular Expression Failed");
            return FastlaneParserStatus.error()
        }

        let statusCodeString = regexStatus.stringByReplacingMatches(in: exitStatusLine, options: [], range: NSMakeRange(0, exitStatusLine.characters.count), withTemplate: "")

        return FastlaneParserStatus.success(exitCode: Int(statusCodeString) ?? -1)
    }
}

fileprivate extension FastlaneParser {

    func lineIsAnalyser(_ line: String) -> Bool {
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

        guard let regex = try? NSRegularExpression(pattern: "\\[[0-9]+(m|;)[0-9]*m?", options: .caseInsensitive) else { print("Regular Expression Failed"); return "" }
        let range = NSMakeRange(0, filteredString.characters.count)
        return regex.stringByReplacingMatches(in: filteredString, options: [], range: range, withTemplate: "")
    }

    func compilerMessages(from: [String]) -> [CompilerMessage] {
        let filteredLines = Set(from.flatMap { line -> CompilerMessage? in
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

        let range = NSMakeRange(0, line.characters.count)
        let matches = regex.matches(in: line, options: .reportCompletion, range: range)
        return matches.count > 0
    }
}
