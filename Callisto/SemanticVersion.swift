//
//  SemanticVersion.swift
//  Callisto
//
//  Created by Patrick Kladek on 23.11.21.
//  Copyright © 2021 IdeasOnCanvas. All rights reserved.
//

import Foundation

struct SemanticVersion {
    let major: Int
    let minor: Int
    let bugfix: Int
    let suffix: String?

    init(major: Int, minor: Int, bugfix: Int, suffix: String? = nil) {
        self.major = major
        self.minor = minor
        self.bugfix = bugfix
        self.suffix = suffix
    }
}

extension SemanticVersion: CustomStringConvertible {

    var description: String {
        return ["\(self.major)", "\(self.minor)", "\(self.bugfix)", self.suffix].compactMap { $0 }.joined(separator: ".")
    }
}

extension SemanticVersion: Equatable { }

extension SemanticVersion: Codable { }

extension SemanticVersion: Hashable { }
