//
//  FailBuildAction.swift
//  Callisto
//
//  Created by Ammad on 03.02.2022.
//  Copyright © 2022 Bikemap. All rights reserved.
//

import Foundation
import ArgumentParser
import Common

// MARK: - FailBuildAction

final class FailBuildAction: AsyncParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "fail-build",
        abstract: "Exit's with code 238 when .buildReport file contains warnings."
    )

    @Argument(help: "Location for .buildReport file", completion: .file())
    var files: [URL] = []

    @Flag
    var verbose: Bool = false

    // MARK: - ParsableCommand

    func run() async throws {
        LoggerInfo.shared.configure(verbose: self.verbose)

        let inputFiles = self.files
        guard inputFiles.hasElements else { quit(.invalidBuildInformationFile) }

        _ = inputFiles.map { log("Processing \($0.absoluteString)") }

        let summaries = inputFiles.map { SummaryFile.read(url: $0) }.compactMap { result -> SummaryFile? in
            switch result {
            case .success(let info):
                return info
            case .failure(let error):
                log("\(error)", level: .error)
                return nil
            }
        }

        let infos: [BuildInformation] = summaries.compactMap { file in
            switch file {
            case .build(let info):
                return info
            default:
                return nil
            }
        }

        let warnings = infos.flatMap { $0.warnings }.uniqued()
        guard warnings.isEmpty else {
            warnings.forEach { log($0.description, level: .warning) }
            quit(.containsWarnings)
        }

        quit(.success)
    }
}
