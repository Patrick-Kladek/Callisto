//
//  Github.swift
//  Callisto
//
//  Created by Patrick Kladek on 02.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser


/// Responsible to read the build summaries and post them to github
final class Github: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "Upload Build Summary to GitHub")

    @Option(help: "Your GitHub Access Token")
    var githubToken: String

    @Option(help: "Your GitHub Organisation Account Name")
    var githubOrganisation: String

    @Option(help: "GitHub Repository Name")
    var githubRepository: String

    @Option(help: "Github Branch")
    var branch: String

    @Flag(help: "Delete previously postet comments from pull request")
    var deletePreviousComments: Bool = false

    @Argument(help: "Location for .buildReport file", completion: .file(), transform: URL.init(fileURLWithPath:))
    var files: [URL] = []

    func run() throws {
        let uploadAction = UploadAction(upload: self)
        try uploadAction.run()
    }
}

final class UploadAction {

    let githubController: GitHubCommunicationController
    let upload: Github

    // MARK: - Lifecycle

    init(upload: Github) {
        self.upload = upload

        let repo = GithubRepository(organisation: upload.githubOrganisation, repository: upload.githubRepository)
        let access = GithubAccess(token: upload.githubToken)
        self.githubController = GitHubCommunicationController(access: access, repository: repo)
    }

    // MARK: - UploadAction

    func run() throws {
        let inputFiles = self.upload.files
        guard inputFiles.hasElements else { quit(.invalidBuildInformationFile) }

        let infos = self.filteredBuildInfos(inputFiles.map { BuildInformation.read(url: $0) }.compactMap { result -> BuildInformation? in
            switch result {
            case .success(let info):
                return info
            case .failure(let error):
                LogError("\(error)")
                return nil
            }
        })

        guard infos.hasElements else { quit(.invalidBuildInformationFile) }

        let currentBranch = self.loadCurrentBranch()
        LogMessage("Did load Branch:")
        LogMessage(" * \(currentBranch.title ?? "<nil>") \(currentBranch.number ?? -1)")
        LogMessage(" * \(currentBranch.url?.absoluteString ?? "<nil>")")

        if self.upload.deletePreviousComments {
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

        if infos.filter({ $0.isEmpty == false }).hasElements {
            let message = "# Build Summary\n\(infos.compactMap { self.markdownText(from: $0) }.joined(separator: "\n"))"
            switch self.githubController.postComment(on: currentBranch, comment: Comment(body: message, id: nil)) {
            case .success:
                LogMessage("Successfully posted BuildReport to GitHub")
            case .failure(let error):
                LogError(error.localizedDescription)
            }
        }

        quit(.success)
    }
}

// MARK: - Private

private extension UploadAction {

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
        switch self.githubController.branch(named: self.upload.branch) {
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
        let allIgnoredKeywords = infos.flatMap { $0.ignoredKeywords }

        return BuildInformation(platform: "Core",
                                errors: commonErrors,
                                warnings: commonWarnings,
                                unitTests: commonUnitTests,
                                ignoredKeywords: allIgnoredKeywords)
    }

    func stripInfos(_ strip: BuildInformation?, from: [BuildInformation]) -> [BuildInformation] {
        guard let strip = strip else { return from }

        return from.map { info -> BuildInformation in
            BuildInformation(platform: info.platform,
                             errors: info.errors.deleting(strip.errors),
                             warnings: info.warnings.deleting(strip.warnings),
                             unitTests: info.unitTests.deleting(strip.unitTests),
                             ignoredKeywords: info.ignoredKeywords.deleting(strip.ignoredKeywords))
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

    func markdownText(from info: BuildInformation) -> String? {
        guard info.errors.hasElements ||
            info.warnings.hasElements ||
            info.unitTests.hasElements else { return nil }

        var string = info.githubSummaryTitle
        string += "\n\n"

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
}

private extension Comment {

    var isCallistoComment: Bool {
        guard self.id != nil else { return false }

        let text = self.body as NSString
        return text.range(of: "# Build Summary\n").location == 0
    }
}
