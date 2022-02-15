//
//  Github.swift
//  Callisto
//
//  Created by Patrick Kladek on 02.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser
import MarkdownKit


/// Responsible to read the build summaries and post them to github
final class PostToGithub: ParsableCommand {

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

    @Argument(help: "Location for .buildReport file", completion: .file(), transform: URL.init(fileURLWithPath:))
    var files: [URL] = []

    // MARK: - ParsableCommand

    func run() throws {
        let uploadAction = GithubAction(command: self)
        try uploadAction.run()
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

    func run() throws {
        let inputFiles = self.command.files
        guard inputFiles.hasElements else { quit(.invalidBuildInformationFile) }

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

        let dependencies = summaries.compactMap { file -> DependencyInformation? in
            switch file {
            case .dependencies(let info):
                return info
            default:
                return nil
            }
        }

        guard infos.hasElements else { quit(.invalidBuildInformationFile) }

        let currentBranch = self.loadCurrentBranch()
        LogMessage("Did load Branch:")
        LogMessage(" * \(currentBranch.title ?? "<nil>") \(currentBranch.number ?? -1)")
        LogMessage(" * \(currentBranch.url?.absoluteString ?? "<nil>")")

        if self.command.deletePreviousComments {
            let result = self.githubController.fetchPreviousComments(on: currentBranch)
            switch result {
            case .failure(let error):
                LogError(error.localizedDescription)
            case .success(let comments):
                let commentsToDelete = comments.filter { $0.isCallistoComment }
                if commentsToDelete.hasElements {
                    LogMessage("Found \(commentsToDelete.count) outdated build comment\(commentsToDelete.count > 1 ? "s" : ""). Deleting ...")
                }
                _ = commentsToDelete.map { comment in
                    switch self.githubController.deleteComment(comment: comment) {
                    case .success:
                        LogMessage("Deleted comment with ID: \(comment.id!)")
                    case .failure(let error):
                        LogError(error.localizedDescription)
                    }
                }
            }
        }


        var document = Document()

        if infos.hasElements {
            document.addComponent(Title("Build Summary", header: .h1))
            document.addComponent(EmptyLine())

            for info in infos {
                document.addComponent(Text(self.markdownText(from: info)))
            }
        }

        if dependencies.hasElements {
            document.addComponent(Title("Dependencies", header: .h3))
            document.addComponent(EmptyLine())


            let outdated = dependencies.flatMap ({ $0.outdated })
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

        let message = document.text()
        LogMessage("Posting Comment on Github")
        print(message)

        switch self.githubController.postComment(on: currentBranch, comment: Comment(body: message, id: nil)) {
        case .success:
            LogMessage("Successfully posted BuildReport to GitHub")
        case .failure(let error):
            LogError(error.localizedDescription)
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

    func loadCurrentBranch() -> Branch {
        switch self.githubController.branch(named: self.command.branch) {
        case .success(let branch):
            return branch
        case .failure(let error):
            LogError(error.localizedDescription)
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
            LogMessage("*** \(info.platform) ***")
            for error in info.errors {
                LogError(error.description)
            }

            for warning in info.warnings {
                LogWarning(warning.description)
            }

            for unitTest in info.unitTests {
                LogWarning(unitTest.description)
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

    /*
    func markdownComponents(from info: BuildInformation) -> [MarkdownConformable] {
        var components: [MarkdownConformable] = []
        components.append(info.githubSummaryText)
        components.append(EmptyLine())
        components.append(EmptyLine())

        if info.errors.isEmpty && info.warnings.isEmpty && info.unitTests.isEmpty {
            components.append(Text("Well done 👍"))
            return components
        }

        if info.errors.hasElements {
            string += "\n\n"
            string += info.errors.map { ":red_circle: **\($0.file):\($0.line)**\n\($0.message)" }.joined(separator: "\n\n")
        }
    }
    */
}

extension Comment {

    var isCallistoComment: Bool {
        guard self.id != nil else { return false }

        let text = self.body as NSString
        return text.range(of: "# Build Summary\n").location == 0
    }
}
