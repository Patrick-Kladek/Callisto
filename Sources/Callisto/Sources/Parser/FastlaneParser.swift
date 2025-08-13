//
//  FastlaneParser.swift
//  clangParser
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation
import Common

class FastlaneParser: BuildOutputParserProtocol {

    enum ParserError: Error {
        case exitStatusNotFound
        case fastlaneRunError
    }

    enum RunStatus {
        case success
        case failure(exitCode: Int)
        case unknown
    }

    private let content: String
    private let config: Config
    private(set) var buildSummary: BuildInformation = .empty
    private(set) var fastlaneReturnValue: RunStatus = .unknown

    // MARK: - Lifecycle

    required init(content: String, config: Config) {
        self.content = content
        self.config = config
    }

    required convenience init(url: URL, config: Config) throws {
        let content = try String(contentsOf: url)
        self.init(content: content, config: config)
    }

    // MARK: - FastlaneParser

    func parse() -> ParsedBuildResult {
        let trimmedContent = self.trimColors(in: self.content)
        let lines = trimmedContent.components(separatedBy: .newlines)

        self.buildSummary = BuildInformation(platform: self.parseSchemeFromFastlane(trimmedContent) ?? "",
                                             errors: self.parseBuildErrors(lines),
                                             warnings: self.parseAnalyzerWarnings(lines),
                                             unitTests: self.parseUnitTestWarnings(lines),
                                             config: self.config)

        self.buildSummary.errors.forEach { log($0.description, level: .error) }
        self.buildSummary.warnings.forEach { log($0.description, level: .warning) }
        self.buildSummary.unitTests.forEach { log($0.description, level: .warning) }

        if let exitCode = self.parseExitStatusFromFastlane(trimmedContent) {
            return .failure(exitCode: exitCode)
        }

        return .success
    }
}

fileprivate extension FastlaneParser {

    func parseSchemeFromFastlane(_ content: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: "\\| scheme[ ]*\\| [a-zA-Z ]*\\|\\n", options: .caseInsensitive) else {
            log("Regular Expression Failed", level: .error)
            return nil
        }

        let schemeLineRange = regex.rangeOfFirstMatch(in: content, options: .reportCompletion, range: NSRange(location: 0, length: content.count))
        guard var schemeLine = content.substring(with: schemeLineRange)?.removeExtraSpaces() else {
            return nil
        }

        schemeLine = schemeLine.replacingOccurrences(of: "| scheme | ", with: "")
        schemeLine = schemeLine.replacingOccurrences(of: " | ", with: "")
        return schemeLine
    }

    func parseBuildErrors(_ lines: [String]) -> [CompilerMessage] {
        let errorLines = lines.filter { self.lineIsError($0) }
        let errors = self.compilerMessages(from: errorLines)

        let filtered = errors.filter({ message in
            guard let rule = self.config.ignore.first(where: { key, _ in
                message.url.absoluteString.contains(key)
            }) else { return true }

            guard let errors = rule.value.errors else { return true }

            return errors.allSatisfy { warning in
                message.message.contains(warning) == false
            }
        })
        return filtered.uniqued()
    }

    func parseAnalyzerWarnings(_ lines: [String]) -> [CompilerMessage] {
        let warningLines = lines.filter { self.lineIsWarning($0) }
        let warnings = self.compilerMessages(from: warningLines)

        let filtered = warnings.filter { message in
            for rule in self.config.ignore {
                let file = rule.key
                if message.url.absoluteString.contains(file) || file == "*" {
                    for warning in (rule.value.warnings ?? []) {
                        if message.message.lowercased().contains(warning.lowercased()) || warning == "*" {
                            return false
                        }
                    }
                }
            }
            return true
        }
        return filtered.uniqued()
    }

    func parseUnitTestWarnings(_ lines: [String]) -> [UnitTestMessage] {
        let unitTestLines = lines.filter { self.lineIsUnitTest($0) }

        let filteredLines = Set(unitTestLines.compactMap { line -> UnitTestMessage? in
            return UnitTestMessage(message: line)
        })

        return Array(filteredLines)
    }

    func parseExitStatusFromFastlane(_ content: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: "\\[[0-9]+:[0-9]+:[0-9]+]: Exit status: [0-9]+", options: .caseInsensitive) else {
            log("Regular Expression Failed", level: .error)
            return nil
        }

        let exitStatusLineRange = regex.rangeOfFirstMatch(in: content, options: .reportCompletion, range: NSRange(location: 0, length: content.count))
        guard let exitStatusLine = content.substring(with: exitStatusLineRange) else {
            // No exit status found means we`re ok
            return nil
        }

        guard let regexStatus = try? NSRegularExpression(pattern: "\\[[0-9]+:[0-9]+:[0-9]+]: Exit status: ", options: .caseInsensitive) else {
            log("Regular Expression Failed", level: .warning)
            return nil
        }

        let statusCodeString = regexStatus.stringByReplacingMatches(in: exitStatusLine, options: [], range: NSRange(location: 0, length: exitStatusLine.count), withTemplate: "")
        let statusCode = Int(statusCodeString) ?? 0
        return statusCode
    }
}

// MARK: - Private

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

        guard let regex = try? NSRegularExpression(pattern: "\\[[0-9]+(m|;)[0-9]*(;)*[0-9]*m?", options: .caseInsensitive) else {
            log("Regular Expression Failed", level: .error)
            return ""
        }

        let range = NSRange(location: 0, length: filteredString.count)
        return regex.stringByReplacingMatches(in: filteredString, options: [], range: range, withTemplate: "")
    }

    func compilerMessages(from: [String]) -> [CompilerMessage] {
        return from.compactMap { line -> CompilerMessage? in
            return CompilerMessage(message: line)
        }
    }

    func check(line: String, withRegex pattern: String) -> Bool {
        let regex: NSRegularExpression

        do {
            try regex = NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch {
            log("error: could not create Regex", level: .error)
            return false
        }

        let range = NSRange(location: 0, length: line.count)
        let matches = regex.matches(in: line, options: .reportCompletion, range: range)
        return matches.hasElements
    }
}

private extension String {

    func removeExtraSpaces() -> String {
        return self.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
    }
}
