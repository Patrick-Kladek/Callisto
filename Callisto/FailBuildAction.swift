//
//  FailBuildAction.swift
//  Callisto
//
//  Created by Ammad on 03/02/2022.
//  Copyright © 2022 Bikemap. All rights reserved.
//

import ArgumentParser
import Foundation


// MARK: - FailBuildAction

final class FailBuildAction: ParsableCommand {

    public static let configuration = CommandConfiguration(commandName: "FailBuild", abstract: "Exit's with code 238 when .buildReport file contains warnings.")

    @Argument(help: "Location for .buildReport file", completion: .file(), transform: URL.init(fileURLWithPath:))
    var files: [URL] = []

    // MARK: - ParsableCommand

    func run() throws {
        let inputFiles = self.files
        guard inputFiles.hasElements else { quit(.invalidBuildInformationFile) }

        _ = inputFiles.map { LogMessage("Processing \($0.absoluteString)") }

        let summaries = inputFiles.map { SummaryFile.read(url: $0) }.compactMap { result -> SummaryFile? in
            switch result {
            case .success(let info):
                return info
            case .failure(let error):
                LogError("\(error)")
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
            warnings.forEach { LogWarning($0.description) }
            quit(.containsWarnings)
        }

        let brokenTests = infos.flatMap { $0.brokenUnitTests }.uniqued()
        guard brokenTests.isEmpty else {
            brokenTests.forEach { LogError("Repeatedly failed: \($0.description)") }
            quit(.containsBrokenTests)
        }

        quit(.success)
    }
}
