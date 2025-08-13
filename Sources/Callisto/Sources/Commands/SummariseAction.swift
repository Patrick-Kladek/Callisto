//
//  SummariseAction.swift
//  Callisto
//
//  Created by Patrick Kladek on 02.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser
import Common
import Yams

/// Handles all steps from parsing the fastlane output to saving it in a temporary location
final class Summarise: AsyncParsableCommand {

    enum Parser: String, ExpressibleByArgument {
        case fastlane
        case xodebuild
    }

    public static let configuration = CommandConfiguration(abstract: "Summarize Output from Fastlane")

    @Option(help: "Compiler Generated Output", completion: .file())
    var buildLog: URL

    @Option(help: "Parser to use")
    var parser: Parser = .xodebuild

    @Option(help: "Location for Output file", completion: .file())
    var output: URL

    @Option(help: "YAML file to exclude messages from specific files", completion: .file())
    var config: URL?

    @Flag
    var verbose: Bool = false

    // MARK: - SummariseAction

    func run() async throws {
        LoggerInfo.shared.configure(verbose: self.verbose)

        let configuration = try self.config.map {
            let decoder = YAMLDecoder()
            let encodedYAML = try String(contentsOf: $0)
            let config = try decoder.decode(Config.self, from: encodedYAML)
            log("Successfully loaded configuration", level: .verbose)
            return config
        } ?? .empty

        var result: ParsedBuildResult
        let buildInfo: BuildInformation
        switch self.parser {
        case .fastlane:
            let extractController = try ExtractBuildInformationController<FastlaneParser>(contentsOfFile: self.buildLog, config: configuration)
            result = extractController.run()
            buildInfo = extractController.buildInfo
        case .xodebuild:
            let extractController = try ExtractBuildInformationController<XcodebuildParser>(contentsOfFile: self.buildLog, config: configuration)
            result = extractController.run()
            buildInfo = extractController.buildInfo
        }

        switch result {
        case .success:
            let snakeCasePlatform = buildInfo.platform.replacingOccurrences(of: " ", with: "_")
            let tempURL = self.output.appendingPathComponent(snakeCasePlatform).appendingPathExtension("buildReport.json")
            let result = buildInfo.save(to: tempURL)
            switch result {
            case .success:
                log("Succesfully saved summarised output at: \(tempURL.path)")
            case .failure(let error):
                log("Saving summary failed: \(error)", level: .error)
                quit(.savingFailed)
            }

        case .failure:
            quit(.parsingFailed)
        }
    }
}
