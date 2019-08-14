//
//  String+Sugar.swift
//  Callisto
//
//  Created by Patrick Kladek on 14.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


extension String {

    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }

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

    func trim(from beginning: String, to endding: String) -> String {
        let string = self as NSString

        let begin = string.range(of: beginning)
        let end = string.range(of: endding)

        guard begin.location != NSNotFound, end.location != NSNotFound else { return self }

        let range = begin.extend(to: end)
        return string.replacingCharacters(in: range, with: "")
    }

    func condenseWhitespace() -> String {
        let components = self.components(separatedBy: .whitespacesAndNewlines)
        return components.filter { !$0.isEmpty }.joined(separator: " ")
    }
}

extension NSRange {

    init(begin: Int, end: Int) {
        self = .init(location: begin, length: end - begin)
    }

    func extend(to range: NSRange) -> NSRange {
        guard self.endPosition < range.endPosition else { return self }

        return NSRange(begin: self.location, end: range.endPosition)
    }

    var endPosition: NSInteger {
        return self.location + self.length
    }
}

