//
//  PodDependencyParser.swift
//  ci-dependencies-check
//
//  Created by Patrick Kladek on 16.11.21.
//

import Foundation

class PodDependencyParser {

    static func parse(content: String) -> [Dependency] {
        let lines = content.split(separator: "\n")
        let filteredLines = lines.filter { $0.starts(with: "-") }
        var dependencies: [Dependency] = []
        for line in filteredLines {
            var components = line.components(separatedBy: " -> ")
            let current = String(components[0].dropFirst(2)).split(separator: " ")
            let name = String(current[0])
            let currentVersionString = String(current[1])
            components = components[1].components(separatedBy: " (")
            let lockedVersionString = String(components[0])
            let latestVersionString = String(components[1].dropLast().replacingOccurrences(of: "latest version ", with: ""))

            let currentVersion = Version(string: currentVersionString)
            let lockedVersion = Version(string: lockedVersionString)
            let latestVersion = Version(string: latestVersionString)

            dependencies.append(Dependency(name: name, currentVersion: currentVersion, lockedVersion: lockedVersion, upgradeableVersion: latestVersion))
        }

        return dependencies
    }
}
