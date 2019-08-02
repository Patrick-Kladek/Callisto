//
//  ExtractBuildInformationController.swift
//  Callisto
//
//  Created by Patrick Kladek on 30.07.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


/// Responsible to extract all build warnings & errors from fastlane
/// output and save this information to a file
final class ExtractBuildInformationController: NSObject {

    enum ExtractError: Error {
        case encodingError
    }

    private var parser: FastlaneParser
    private var ignore: [String]

    // MARK: - Properties

    var buildInfo: BuildInformation {
        return self.parser.buildSummary
    }

    // MARK: - Lifecycle

    init?(contentsOfFile url: URL, ignoredKeywords: [String]) {
        guard let parser = FastlaneParser(url: url, ignoredKeywords: ignoredKeywords) else { return nil }

        self.parser = parser
        self.ignore = ignoredKeywords
    }

    // MARK: - ExtractBuildInformationController

    func run() -> Result<Int, Error> {
        let code = self.parser.parse()
        return .success(code)
    }

    func save(to url: URL) -> Result<Int, Error> {
        let buildSummary = self.parser.buildSummary
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        guard let data = try? encoder.encode(buildSummary) else { return .failure(ExtractError.encodingError)}

        do {
            try FileManager().createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            try data.write(to: url, options: [.atomic])
        } catch {
            return .failure(error)
        }

        return .success(0)
    }
}
