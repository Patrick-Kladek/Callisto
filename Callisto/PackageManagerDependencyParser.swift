//
//  PackageManagerDependencyParser.swift
//  Callisto
//
//  Created by Patrick Kladek on 24.05.22.
//  Copyright © 2022 IdeasOnCanvas. All rights reserved.
//

import Foundation

class PackageManagerDependencyParser {

    static func parse(content: String) -> [Dependency] {
        let lines = content.split(separator: "\n")
        guard lines.count > 4 else { return [] }

        let filteredLines = lines[3..<lines.count-2]
        var dependencies: [Dependency] = []
        for line in filteredLines {
            var components = line.components(separatedBy: .whitespaces)
            components.removeAll(where: { $0.count == 0 })
            let name = String(components[0])
            let currentVersionString = String(components[1])
            let latestVersionString = String(components[2])

            let currentVersion = Version(string: currentVersionString)
            let latestVersion = Version(string: latestVersionString)

            dependencies.append(Dependency(name: name, currentVersion: currentVersion, lockedVersion: nil, upgradeableVersion: latestVersion))
        }

        return dependencies
    }
}
