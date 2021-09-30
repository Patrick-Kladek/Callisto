//
//  SummariseAction.swift
//  Callisto
//
//  Created by Patrick Kladek on 02.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser


/// Handles all steps from parsing the fastlane output to saving it in a temporary location
final class Summarise: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "Summarize Output from Fastlane")

    @Option(help: "Fastlane Generated Output", completion: .file(), transform: {
        return URL.init(fileURLWithPath: $0)
    })
    var fastlane: URL

    @Option(help: "Location for Output file", completion: .file(), transform: URL.init(fileURLWithPath:))
    var output: URL

    @Argument(help: "Ignore Messages which contain keywords")
    var ignore: [String] = []

    // MARK: - SummariseAction

    func run() throws {
        let extractController = try ExtractBuildInformationController(contentsOfFile: self.fastlane, ignoredKeywords: self.ignore)

        switch extractController.run() {
        case .success(let fastlaneStatusCode):
            let snakeCasePlatform = extractController.buildInfo.platform.replacingOccurrences(of: " ", with: "_")
            let tempURL = self.output.appendingPathComponent(snakeCasePlatform).appendingPathExtension("buildReport")
            let result = extractController.save(to: tempURL)
            switch result {
            case .success:
                LogMessage("Succesfully saved summarised output at: \(tempURL.path)")
                quit(fastlaneStatusCode == 0 ? .success : .fastlaneFinishedWithErrors)
            case .failure(let error):
                LogError("Saving summary failed: \(error)")
                quit(.savingFailed)
            }

        case .failure:
            quit(.parsingFailed)
        }
    }
}

