//
//  CompilerMessage.swift
//  clangParser
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

class CompilerMessage {

    public let fileName: String
    public let url: URL
    public let line: NSInteger
    public let column: NSInteger
    public let message: String

    init?(message: String) {
        guard let slashRange = message.range(of: "/") else { return nil }

        let validMessage = message[slashRange.lowerBound...]
        let components = validMessage.components(separatedBy: ":")
        guard components.count >= 4 else { return nil }

        let path = components[0]
        let line = components[1]
        let column = components[2]
        let message = components.dropFirst(3).joined(separator: ":")

        self.url = URL(fileURLWithPath: path)
        self.fileName = self.url.lastPathComponent
        self.line = Int(line) ?? -1
        self.column = Int(column) ?? -1
        self.message = message
    }
}

extension CompilerMessage: CustomStringConvertible {

    var description: String {
        return "\(self.fileName) [Line: \(self.line)] \(self.message)"
    }
}

extension CompilerMessage: Hashable {

    static func == (left: CompilerMessage, right: CompilerMessage) -> Bool {
        return
            left.fileName == right.fileName &&
            left.line == right.line &&
            left.column == right.column &&
            left.message == right.message
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.fileName)
        hasher.combine(self.line)
        hasher.combine(self.message)
    }
}

fileprivate extension CompilerMessage {

    func substringFromRegex(pattern: String, message: String) -> String? {
        let regex: NSRegularExpression

        do {
            try regex = NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        } catch {
            print("error: could not create Regex")
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

extension String {

    /// An `NSRange` that represents the full range of the string.
    var nsrange: NSRange {
        return NSRange(location: 0, length: utf16.count)
    }

    /// Returns a substring with the given `NSRange`,
    /// or `nil` if the range can't be converted.
    func substring(with nsrange: NSRange) -> String? {
        guard let range = Range(nsrange, in: self) else { return nil }
        return String(self[range])
    }
}
