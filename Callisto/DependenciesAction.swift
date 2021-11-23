//
//  DependenciesAction.swift
//  Callisto
//
//  Created by Patrick Kladek on 23.11.21.
//  Copyright © 2021 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser
import MarkdownKit


/// Handles all steps from parsing the fastlane output to saving it in a temporary location
final class Dependencies: ParsableCommand {

    @Option(help: "Location of Project Folder", completion: .file(), transform: URL.init(fileURLWithPath:))
    var project: URL

    @Option(help: "Summary file is written to location", completion: .file(), transform: URL.init(fileURLWithPath:))
    var output: URL

    @Option(help: "Ignored Dependencies", transform: { string in
        string.components(separatedBy: " ")
    })
    var ignore: [String] = []

    @Flag(help: "When set exits with non zero status code which in turn will fail build pipeline")
    var failPipeline: Bool = false

    func run() throws {
        let output = self.shell("pod outdated", currentDirectoryURL: self.project)
        print(">>> pod outdated ...")
        print(output)
        let dependencies = PodDependencyParser.parse(content: output)

        let filtered = PodDependencyParser.filter(dependencies: dependencies, with: self.ignore)
        let ignored = filtered.difference(from: dependencies)

        print("Outdated Pods: \(filtered)")

        let info = DependencyInformation(outdated: filtered, ignored: ignored)
        let summary = SummaryFile.dependencies(info)

        print("Writing to file ...")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        let data = try encoder.encode(summary)

        try data.write(to: self.output)

        if self.failPipeline && filtered.hasElements {
            throw ExitCode(1)
        }
    }
}

// MARK: - Private

private extension Dependencies {

    func shell(_ command: String, currentDirectoryURL: URL? = nil) -> String {
        let task = Process()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let environment = [
            "LANG": "en_US.UTF-8",
            "PATH": [
                "/usr/local/bin",
                "/usr/bin",
                "/bin",
                "/usr/sbin",
                "/sbin",
            ].joined(separator: ":")
        ]

        task.standardOutput = outputPipe
        task.standardError = errorPipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.environment = environment
        task.currentDirectoryURL = currentDirectoryURL
        task.launch()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!

        return output
    }

    func makeOutdatedDocument(from dependencies: [Dependency]) -> Document {
        var doc = Document()
        doc.addComponent(Title("New Version Available", header: .h3))
        doc.addComponent(EmptyLine())

        var table = Table(titles: Table.Row(columns: ["Library", "Current", "New"]))
        let rows = dependencies.map { Table.Row(columns: [$0.name, $0.currentVersion.description, $0.upgradeableVersion.description]) }
        table.addRows(rows)
        doc.addComponent(table)

        doc.addComponent(EmptyLine())
        doc.addComponent(Text("Update Version in Pofile and then run `pod update`"))

        return doc
    }

    func makeUpdatedDocument() -> Document {
        var doc = Document()
        doc.addComponent(Title("All Dependencies up-to-date 👍", header: .h3))
        return doc
    }
}
