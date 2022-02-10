//
//  FailBuildAction.swift
//  Callisto
//
//  Created by Ammad on 03/02/2022.
//  Copyright © 2022 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser
import MarkdownKit

// MARK: - FailBuildAction
final class FailBuildAction: ParsableCommand {
    public static let configuration = CommandConfiguration(commandName: "FailBuild", abstract: "Exit with zero when there are no warnings.")

    @Argument(help: "Location for .buildReport file", completion: .file(), transform: URL.init(fileURLWithPath:))
    var files: [URL] = []
    
    func run() throws {
        let uploadAction = GithubWarningsAction(command: self)
        try uploadAction.run()
    }
}

// MARK: - GithubWarningsAction
final class GithubWarningsAction {

    let command: FailBuildAction

    // MARK: - Lifecycle

    init(command: FailBuildAction) {
        self.command = command
    }

    // MARK: - UploadAction

    func run() throws {
        let inputFiles = self.command.files
        
        guard inputFiles.hasElements else {
            quit(.invalidBuildInformationFile)
        }

        LogMessage("Input Files: ")
        _ = inputFiles.map { LogMessage($0.absoluteString) }

        let summaries = inputFiles.map { SummaryFile.read(url: $0) }.compactMap { result -> SummaryFile? in
            switch result {
            case .success(let info):
                return info
            case .failure(let error):
                LogError("\(error)")
                return nil
            }
        }

        let infos = self.filteredBuildInfos(summaries.compactMap { file in
            switch file {
            case .build(let info):
                return info
            default:
                return nil
            }
        })
        
        let inforWarnings = infos.flatMap { $0.warnings }

        guard inforWarnings.isEmpty else {
            quit(.containsWarnings)
        }

        quit(.success)
    }
}

// MARK: - Private

private extension GithubWarningsAction {

    func filteredBuildInfos(_ infos: [BuildInformation]) -> [BuildInformation] {
        let coreInfos = self.commonInfos(infos)
        let stripped = self.stripInfos(coreInfos, from: infos)

        var allBuildInfos = stripped
        if let coreInfos = coreInfos {
            allBuildInfos.append(coreInfos)
        }

        return allBuildInfos
    }

    func commonInfos(_ infos: [BuildInformation]) -> BuildInformation? {
        guard infos.count > 1 else { return nil }

        let commonErrors = infos[0].errors.filter { infos[1].errors.contains($0) }
        let commonWarnings = infos[0].warnings.filter { infos[1].warnings.contains($0) }
        let commonUnitTests = infos[0].unitTests.filter { infos[1].unitTests.contains($0) }

        return BuildInformation(platform: "Core",
                                errors: commonErrors,
                                warnings: commonWarnings,
                                unitTests: commonUnitTests,
                                config: .empty)
    }

    func stripInfos(_ strip: BuildInformation?, from: [BuildInformation]) -> [BuildInformation] {
        guard let strip = strip else { return from }

        return from.map { info -> BuildInformation in
            BuildInformation(platform: info.platform,
                             errors: info.errors.deleting(strip.errors),
                             warnings: info.warnings.deleting(strip.warnings),
                             unitTests: info.unitTests.deleting(strip.unitTests),
                             config: .empty)
        }
    }

}
