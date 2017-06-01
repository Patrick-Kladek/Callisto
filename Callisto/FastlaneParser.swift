//
//  FastlaneParser.swift
//  clangParser
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

class FastlaneParser {

    fileprivate let content: String
    fileprivate let ignoredKeywords: [String]
     private(set) var staticAnalyzerMessages: [CompilerMessage] = []

    init(content: String, ignoredKeywords: [String]? = nil) {
        self.content = content
        self.ignoredKeywords = ignoredKeywords ?? []
    }

    convenience init?(url: URL, ignoredKeywords: [String]? = nil) {
        guard let content = try? String(contentsOf: url) else { return nil }
        self.init(content: content, ignoredKeywords: ignoredKeywords)
    }

    func parse() -> Bool {
        let trimmedContent = self.trimColors(in: self.content)
        self.staticAnalyzerMessages.append(contentsOf: self.parseContent(trimmedContent))
        return true
    }
}

fileprivate extension FastlaneParser {

    func trimColors(in input: String) -> String {
        let colors = ["[0m",  "[1m",  "[2m",  "[3m",  "[4m",  "[5m",  "[6m",  "[7m", "[8m",
                      "[30m", "[31m", "[32m", "[33m", "[34m", "[35m", "[36m", "[37m",
                      "[40m", "[41m", "[42m", "[43m", "[44m", "[45m", "[46m", "[47m",
                      "\u{1B}"]

        var temp = input
        for color in colors {
            temp = temp.replacingOccurrences(of: color, with: "")
        }
        return temp
    }

    func parseContent(_ content: String) -> [CompilerMessage] {
        let lines = content.components(separatedBy: .newlines).filter { self.lineIsAnalyser($0) }

        let filteredLines = Set(lines.flatMap { line -> CompilerMessage? in
            for keyword in self.ignoredKeywords {
                guard line.lowercased().contains(keyword) == false else { return nil }
            }
            
            return CompilerMessage(message: line)
        })

        return Array(filteredLines)
    }

    func lineIsAnalyser(_ line: String) -> Bool {
        let pattern = "⚠️"
        return self.check(line: line, withRegex: pattern)
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
