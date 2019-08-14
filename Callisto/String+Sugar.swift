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
}
