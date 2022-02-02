//
//  ExtractBuildInformationController.swift
//  Callisto
//
//  Created by Patrick Kladek on 30.07.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


struct Config: Codable {
    typealias File = String

    struct Details: Codable {
        let warnings: [String]?
        let errors: [String]?
        let tests: [String]?
    }

    let ignore: [File: Details]

    static let empty = Config(ignore: [:])
}

/// Responsible to extract all build warnings & errors from fastlane
/// output and save this information to a file
final class ExtractBuildInformationController: NSObject {

    enum ExtractError: Error {
        case encodingError
    }

    private var parser: FastlaneParser
    private var config: Config

    // MARK: - Properties

    var buildInfo: BuildInformation {
        return self.parser.buildSummary
    }

    // MARK: - Lifecycle

    init(contentsOfFile url: URL, config: Config) throws {
        let parser = try FastlaneParser(url: url, config: config)

        self.parser = parser
        self.config = config
    }

    // MARK: - ExtractBuildInformationController

    func run() -> Result<Int, Error> {
        let code = self.parser.parse()
        return .success(code)
    }

    func save(to url: URL) -> Result<Int, Error> {
        let buildInformation = self.parser.buildSummary
        let summary = SummaryFile.build(buildInformation)
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
