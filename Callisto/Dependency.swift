//
//  Dependency.swift
//  ci-dependencies-check
//
//  Created by Patrick Kladek on 16.11.21.
//

import Foundation
import MarkdownKit

struct Dependency {
    let name: String
    let currentVersion: Version
    let lockedVersion: Version
    let upgradeableVersion: Version
}

extension Dependency: CustomStringConvertible {

    var description: String {
        return "\(self.name) \(self.currentVersion)"
    }
}

extension Dependency: Equatable { }

extension Dependency: Codable { }

extension Dependency: Hashable { }
