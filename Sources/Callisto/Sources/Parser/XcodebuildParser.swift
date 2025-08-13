//
//  XcodebuildParser.swift
//  Callisto
//
//  Created by Patrick Kladek on 13.08.25.
//  Copyright © 2025 IdeasOnCanvas. All rights reserved.
//

import Foundation
import Common

enum ParsedBuildResult: Equatable {
    case success
    case failure(exitCode: Int?)
}

protocol BuildOutputParserProtocol {

    var buildSummary: BuildInformation { get }

    init(content: String, config: Config)
    init(url: URL, config: Config) throws

    func parse() -> ParsedBuildResult
}

class XcodebuildParser: BuildOutputParserProtocol {

    private let content: String
    private let config: Config
    private(set) var buildSummary: BuildInformation = .empty

    // MARK: - Lifecycle

    required init(content: String, config: Config) {
        self.content = content
        self.config = config
    }

    required convenience init(url: URL, config: Config) throws {
        let content = try String(contentsOf: url)
        self.init(content: content, config: config)
    }

    // MARK: - XcodebuildParser

    func parse() -> ParsedBuildResult {
        let lines = self.content.components(separatedBy: .newlines)

        self.buildSummary = BuildInformation(platform: self.parseScheme(from: self.content) ?? "",
                                            errors: self.parseErrors(lines),
                                            warnings: self.parseWarnings(lines),
                                            unitTests: self.parseUnitTestWarnings(lines),
                                            config: self.config)

        self.buildSummary.errors.forEach { log($0.description, level: .error) }
        self.buildSummary.warnings.forEach { log($0.description, level: .warning) }
        self.buildSummary.unitTests.forEach { log($0.description, level: .warning) }

        if let exitCode = self.parseExitStatusFromFastlane(self.content) {
            return .failure(exitCode: exitCode)
        }

        return .success
    }
}

fileprivate extension XcodebuildParser {

    func parseScheme(from content: String) -> String? {
        let pattern = #"-scheme\s+(?:"([^"]+)"|(\S+))"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            log("Regular Expression Failed", level: .error)
            return nil
        }

        let schemeLineRange = regex.rangeOfFirstMatch(in: content, options: .reportCompletion, range: NSRange(location: 0, length: content.count))
        guard var schemeLine = content.substring(with: schemeLineRange)?.removeExtraSpaces() else {
            return nil
        }

        schemeLine.replace("-scheme ", with: "")

        return schemeLine
    }

    func parseErrors(_ lines: [String]) -> [CompilerMessage] {
        let errorLines = lines.filter { $0.isError() }
        let errors = errorLines.compilerMessages()

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

    func parseWarnings(_ lines: [String]) -> [CompilerMessage] {
        let warningLines = lines.filter { $0.isWarning() }
        let warnings = warningLines.compilerMessages()

        let filtered = warnings.filter { message in
            for rule in self.config.ignore {
                let file = rule.key
                if message.url.absoluteString.contains(file) || file == "*" {
                    for warning in (rule.value.warnings ?? []) {
                        if message.message.lowercased().contains(warning.lowercased()) || warning == "*" {
                            log("Ignore warning as it matches rule: '\(message.description)", level: .verbose)
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
        let unitTestLines = lines.filter { $0.isUnitTest() }

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
        let statusCode = Int(statusCodeString)
        return statusCode
    }
}

// MARK: - Private

private extension String {

    func isWarning() -> Bool {
        let pattern = "warning: "
        return self.matches(regex: pattern)
    }

    func isError() -> Bool {
        let pattern = "error: "
        return self.matches(regex: pattern)
    }

    func isUnitTest() -> Bool {
        let pattern = "failed:"
        return self.matches(regex: pattern)
    }

    func matches(regex pattern: String) -> Bool {
        let regex: NSRegularExpression

        do {
            try regex = NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch {
            log("error: could not create Regex", level: .error)
            return false
        }

        let range = NSRange(location: 0, length: self.count)
        let matches = regex.matches(in: self, options: .reportCompletion, range: range)
        return matches.hasElements
    }

    func removeExtraSpaces() -> String {
        return self.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
    }
}

private extension Array where Element == String {

    func compilerMessages() -> [CompilerMessage] {
        return self.compactMap { line -> CompilerMessage? in
            return CompilerMessage(message: line)
        }
    }
}
