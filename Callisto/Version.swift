//
//  Version.swift
//  ci-dependencies-check
//
//  Created by Patrick Kladek on 16.11.21.
//

import Foundation

enum Version {
    case semantic(SemanticVersion)
    case other(String)

    init(string: String) {
        if let version = string.semanticVersion {
            self = .semantic(version)
        } else {
            self = .other(string)
        }
    }
}

extension Version: CustomStringConvertible {

    var description: String {
        switch self {
        case .semantic(let version):
            return version.description
        case .other(let string):
            return string
        }
    }
}

extension Version: Equatable { }

extension Version: Codable { }

extension Version: Hashable { }

extension String {

    var isSemanticVersion: Bool {
        let components = self.split { char in
            return char == "." || char == "-"
        }
        return components.count >= 3 &&
        components[0].allSatisfy { $0.isNumber } &&
        components[1].allSatisfy { $0.isNumber } &&
        components[2].first!.isNumber
    }

    var semanticVersion: SemanticVersion? {
        guard self.isSemanticVersion else { return nil }

        let components = self.split { char in
            return char == "." || char == "-"
        }

        var suffix: String? = nil
        if components.count > 3 {
            suffix = components[3...(components.count-1)].map { String($0) }.joined(separator: ".")
        }

        return SemanticVersion(major: Int(components[0])!,
                               minor: Int(components[1])!,
                               bugfix: Int(components[2])!,
                               suffix: suffix)
    }
}
