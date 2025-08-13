//
//  CompilerMessage.swift
//  clangParser
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

class CompilerMessage: Codable {

    public let file: String
    public let url: URL
    public let line: NSInteger
    public let column: NSInteger
    public let message: String

    // MARK: Lifecycle

    init?(message: String) {
        guard let slashRange = message.range(of: "/") else {
            return nil
        }

        let validMessage = message[slashRange.lowerBound...]
        let components = validMessage.components(separatedBy: ":")
        guard components.count >= 4 else {
            return nil
        }

        let path = components[0]
        let line = components[1]
        let column = components[2]
        let message = components.dropFirst(3).joined(separator: ":")

        self.url = URL(fileURLWithPath: path)
        self.file = self.url.lastPathComponent
        self.line = Int(line) ?? -1
        self.column = Int(column) ?? -1
        self.message = message.dropWarningFlag().trim().replacingOccurrences(of: "'", with: "`").condenseWhitespace()
    }
}

extension CompilerMessage: CustomStringConvertible {

    var description: String {
        return "\(self.file) [Line: \(self.line)] \(self.message)"
    }
}

extension CompilerMessage: Hashable {

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.file)
        hasher.combine(self.line)
        hasher.combine(self.message)
    }
}

extension CompilerMessage: Equatable {

    static func == (left: CompilerMessage, right: CompilerMessage) -> Bool {
        return (
            left.file == right.file &&
            left.line == right.line &&
            left.column == right.column &&
            left.message == right.message
        )
    }
}

fileprivate extension CompilerMessage {

    func substringFromRegex(pattern: String, message: String) -> String? {
        let regex: NSRegularExpression

        do {
            try regex = NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch {
            log("error: could not create Regex", level: .error)
            return nil
        }

        let matches = regex.matches(in: message, options: .reportCompletion, range: NSMakeRange(0, message.count))

        for match in matches {
            let range = match.range(at: 1)
            return message.substring(with: range)
        }

        return nil
    }
}
private extension String {

    func dropWarningFlag() -> String {
        return self.trim(from: "[-W", to: "]")
    }
}
