//
//  CompilerRun.swift
//  Callisto
//
//  Created by Patrick Kladek on 30.07.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation
import MarkdownKit


/// Holds all information about a compiler run
struct BuildInformation: Codable, Equatable {

    let platform: String
    let errors: [CompilerMessage]
    let warnings: [CompilerMessage]
    let unitTests: [UnitTestMessage]
    let config: Config

    static let empty = BuildInformation(platform: "",
                                        errors: [],
                                        warnings: [],
                                        unitTests: [],
                                        config: Config.empty)
}

extension BuildInformation {

    func save(to url: URL) -> Result<Int, Error> {
        let summary = SummaryFile.build(self)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        guard let data = try? encoder.encode(summary) else { return .failure(ExtractError.encodingError)}

        do {
            try FileManager().createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try data.write(to: url, options: [.atomic])
        } catch {
            return .failure(error)
        }

        return .success(0)
    }
}

extension BuildInformation {

    enum ExtractError: Error {
        case encodingError
    }

    var isEmpty: Bool {
        return self.errors.isEmpty && self.warnings.isEmpty && self.unitTests.isEmpty
    }

    var githubSummaryTitle: String {
        func descriptionCount(of array: [AnyHashable]) -> String {
            if array.isEmpty {
                return "no"
            } else {
                return "\(array.count)"
            }
        }
        return "### \(self.platform) - \(descriptionCount(of: self.warnings)) warnings, \(descriptionCount(of: self.errors)) errors"
    }

    var githubSummaryText: Title {
        func descriptionCount(of array: [AnyHashable]) -> String {
            if array.isEmpty {
                return "no"
            } else {
                return "\(array.count)"
            }
        }
        return Title("\(self.platform) - \(descriptionCount(of: self.warnings)) warnings, \(descriptionCount(of: self.errors)) errors", header: .h3)
    }
}
