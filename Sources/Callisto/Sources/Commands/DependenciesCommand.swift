//
//  DependenciesCommand.swift
//  Callisto
//
//  Created by Patrick Kladek on 23.11.21.
//  Copyright © 2021 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser
import MarkdownKit
import Common

/// Handles all steps from parsing the fastlane output to saving it in a temporary location
final class DependenciesCommand: AsyncParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "dependencies",
        abstract: "Spot outdated dependencies in Project"
    )

    @Option(help: "Location of Project Folder", completion: .file())
    var project: URL

    @Option(help: "Summary file is written to location", completion: .file())
    var output: URL

    @Option(help: "Ignored Dependencies", transform: { string in
        string.components(separatedBy: " ")
    })
    var ignore: [String] = []

    @Flag(help: "When set exits with non zero status code which in turn will fail build pipeline")
    var failPipeline: Bool = false

    @Flag
    var verbose: Bool = false

    func run() throws {
        LoggerInfo.shared.configure(verbose: self.verbose)

        let podOutout = self.shell("pod outdated", currentDirectoryURL: self.project)
        log(podOutout)
        let podDependencies = PodDependencyParser.parse(content: podOutout)

        let pmOutput = self.shell("swift outdated", currentDirectoryURL: self.project)
        log(pmOutput)
        let pmDependencies = PackageManagerDependencyParser.parse(content: pmOutput)

        let dependencies = podDependencies + pmDependencies
        let filtered = Self.filter(dependencies: dependencies, with: self.ignore)
        let ignored = filtered.difference(from: dependencies)

        log("Outdated Dependencies: \(filtered)")

        let info = DependencyInformation(outdated: filtered, ignored: ignored)
        let summary = SummaryFile.dependencies(info)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(summary)

        try data.write(to: self.output)

        log("Summary written to: \(self.output.absoluteString)")

        if self.failPipeline && filtered.hasElements {
            throw ExitCode(1)
        }
    }
}

// MARK: - Private

private extension DependenciesCommand {

    func shell(_ command: String, currentDirectoryURL: URL? = nil) -> String {
        let task = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()

        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.environment = ProcessInfo.processInfo.environment
        task.currentDirectoryURL = currentDirectoryURL

        log("$ \(command)")

        task.launch()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        let errorOutput = String(data: errorData, encoding: .utf8)!
        if errorOutput.hasElements {
            log(errorOutput, level: .error)
        }

        return output
    }

    static func filter(dependencies: [Dependency], with keywords: [String]) -> [Dependency] {
        return Array(dependencies.drop { keywords.contains($0.name) })
    }
}
