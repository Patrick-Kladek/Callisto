//
//  ExtractBuildInformationController.swift
//  Callisto
//
//  Created by Patrick Kladek on 30.07.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation

struct Config: Codable, Equatable {
    typealias File = String

    struct Details: Codable, Equatable {
        let warnings: [String]?
        let errors: [String]?
        let tests: [String]?
    }

    let ignore: [File: Details]

    static let empty = Config(ignore: [:])
}

/// Responsible to extract all build warnings & errors from fastlane
/// output and save this information to a file
final class ExtractBuildInformationController<Parser: BuildOutputParserProtocol> {

    enum ExtractError: Error {
        case encodingError
    }

    private var parser: Parser
    private var config: Config

    // MARK: - Properties

    var buildInfo: BuildInformation {
        return self.parser.buildSummary
    }

    // MARK: - Lifecycle

    init(contentsOfFile url: URL, config: Config) throws {
        let parser = try Parser(url: url, config: config)

        self.parser = parser
        self.config = config
    }

    // MARK: - ExtractBuildInformationController

    func run() -> ParsedBuildResult {
        return self.parser.parse()
    }
}
