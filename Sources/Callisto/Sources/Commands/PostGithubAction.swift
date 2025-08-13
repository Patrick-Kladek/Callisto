//
//  PostGithubAction.swift
//  Callisto
//
//  Created by Patrick Kladek on 02.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser
import MarkdownKit
import Common
import GithubKit

/// Responsible to read the build summaries and post them to github
final class PostToGithub: AsyncParsableCommand {

    public static let configuration = CommandConfiguration(commandName: "github", abstract: "Upload Build Summary to Github")

    @Option(help: "Your GitHub Access Token")
    var githubToken: String

    @Option(help: "Your GitHub Organisation Account Name")
    var githubOrganisation: String

    @Option(help: "GitHub Repository Name")
    var githubRepository: String

    @Option(help: "GitHub Branch")
    var branch: String

    @Flag(help: "Delete previously postet comments from pull request")
    var deletePreviousComments: Bool = false

    @Option(help: "URL to an external website hosting a HTML Report (XCTestHTMLReport)", completion: .file(), transform: URL.init(string:)) // swiftlint:disable:this init_usage
    var htmlReport: URL?

    @Argument(help: "Location for .buildReport file", completion: .file())
    var files: [URL] = []

    // MARK: - ParsableCommand

    func run() async throws {
        let uploadAction = GithubAction(command: self)
        try await uploadAction.run()
    }
}

// MARK: - GithubAction

final class GithubAction {

    let githubController: GitHubCommunicationController
    let command: PostToGithub

    // MARK: - Lifecycle

    init(command: PostToGithub) {
        self.command = command

        let repo = GithubRepository(organisation: command.githubOrganisation, repository: command.githubRepository)
        let access = GithubAccess(token: command.githubToken)
        self.githubController = GitHubCommunicationController(access: access, repository: repo)
    }

    // MARK: - GithubAction

    func run() async throws {
        let inputFiles = self.command.files
        guard inputFiles.hasElements else { quit(.invalidBuildInformationFile) }

        log("Input Files: ")
        _ = inputFiles.map { log($0.absoluteString) }

        let summaries = inputFiles.map { SummaryFile.read(url: $0) }.compactMap { result -> SummaryFile? in
            switch result {
            case .success(let info):
                return info
            case .failure(let error):
                log("\(error)", level: .error)
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

        let dependencies = summaries.compactMap { file -> DependencyInformation? in
            switch file {
            case .dependencies(let info):
                return info
            default:
                return nil
            }
        }

        guard infos.hasElements else { quit(.invalidBuildInformationFile) }

        let currentBranch = await self.loadCurrentBranch()
        log("Did load Branch:")
        log(" * \(currentBranch.title ?? "<nil>") \(currentBranch.number ?? -1)")
        log(" * \(currentBranch.url?.absoluteString ?? "<nil>")")

        if self.command.deletePreviousComments {
            let result = try await self.githubController.fetchPreviousComments(on: currentBranch)
            switch result {
            case .failure(let error):
                log(error.localizedDescription, level: .error)
            case .success(let comments):
                let commentsToDelete = comments.filter { $0.isCallistoComment }
                if commentsToDelete.hasElements {
                    log("Found \(commentsToDelete.count) outdated build comment\(commentsToDelete.count > 1 ? "s" : ""). Deleting ...")
                }
                for comment in commentsToDelete {
                    switch try await self.githubController.deleteComment(comment: comment) {
                    case .success:
                        log("Deleted comment with ID: \(comment.id!)")
                    case .failure(let error):
                        log(error.localizedDescription, level: .error)
                    }
                }
            }
        }

        let document = self.buildDocument(infos: infos, dependencies: dependencies)

        let message = document.text()
        log("Posting Comment on Github")
        log(message)

        switch try await self.githubController.postComment(on: currentBranch, comment: Comment(body: message, id: nil)) {
        case .success:
            log("Successfully posted BuildReport to GitHub", level: .success)
        case .failure(let error):
            log(error.localizedDescription, level: .error)
        }

        quit(.success)
    }
}

// MARK: - Private

private extension GithubAction {

    func filteredBuildInfos(_ infos: [BuildInformation]) -> [BuildInformation] {
        let coreInfos = self.commonInfos(infos)
        let stripped = self.stripInfos(coreInfos, from: infos)

        var allBuildInfos = stripped
        if let coreInfos = coreInfos {
            allBuildInfos.append(coreInfos)
        }

        return allBuildInfos
    }

    func loadCurrentBranch() async -> Branch {
        switch await self.githubController.branch(named: self.command.branch) {
        case .success(let branch):
            return branch
        case .failure(let error):
            log(error.localizedDescription, level: .error)
            quit(.reloadBranchFailed)
        }
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

    func logBuildInfo(_ infos: [BuildInformation]) {
        for info in infos {
            log("*** \(info.platform) ***")
            for error in info.errors {
                log(error.description, level: .error)
            }

            for warning in info.warnings {
                log(warning.description, level: .warning)
            }

            for unitTest in info.unitTests {
                log(unitTest.description, level: .warning)
            }
        }
    }

    func markdownText(from info: BuildInformation) -> String {
        var string = info.githubSummaryTitle

        if info.errors.isEmpty && info.warnings.isEmpty && info.unitTests.isEmpty {
            string += "\n\n"
            string += "Well done 👍"
            return string
        }

        if info.errors.hasElements {
            string += "\n\n"
            string += info.errors.map { ":red_circle: **\($0.file):\($0.line)**\n\($0.message)" }.joined(separator: "\n\n")
        }

        if info.warnings.hasElements {
            string += "\n\n"
            string += info.warnings.map { ":warning: **\($0.file):\($0.line)**\n\($0.message)" }.joined(separator: "\n\n")
        }

        if info.unitTests.hasElements {
            string += "\n\n"
            string += info.unitTests.map { ":large_blue_circle: `\($0.method)`\n\($0.assertType)\n\($0.explanation)" }.joined(separator: "\n\n")
        }

        string += "\n\n"
        return string
    }

    func buildDocument(infos: [BuildInformation], dependencies: [DependencyInformation]) -> Document {
        var document = Document()

        if infos.hasElements {
            document.addComponent(Title("Build Summary", header: .h1))
            document.addComponent(EmptyLine())

            for info in infos {
                document.addComponent(Text(self.markdownText(from: info)))
            }
            document.addComponent(EmptyLine())
        }

        if let htmlReport = self.command.htmlReport {
            document.addComponent(Link("Detailed Test Report", url: htmlReport))
            document.addComponent(EmptyLine())
        }

        if dependencies.hasElements {
            document.addComponent(Title("Dependencies", header: .h3))
            document.addComponent(EmptyLine())

            let outdated = dependencies.flatMap { $0.outdated }
            if outdated.hasElements {
                var table = Table(titles: Table.Row(columns: ["Name", "Current", "New"]))
                for dependency in outdated {
                    let row = Table.Row(columns: [
                        dependency.name,
                        dependency.currentVersion.description,
                        dependency.upgradeableVersion.description
                    ])

                    table.addRow(row)
                }
                document.addComponent(table)
            } else {
                document.addComponent(Text("Everything Up-to-date 👍"))
            }
        }

        return document
    }
}

extension Comment {

    var isCallistoComment: Bool {
        guard self.id != nil else { return false }

        let text = self.body as NSString
        return text.range(of: "# Build Summary\n").location == 0
    }
}
