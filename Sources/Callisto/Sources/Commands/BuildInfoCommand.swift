//
//  BuildInfoCommand.swift
//  Callisto
//
//  Created by Patrick Kladek on 13.08.25.
//

import Foundation
import ArgumentParser

// swiftlint:disable print_usage
final class BuildInfoCommand: AsyncParsableCommand {

    public static let configuration = CommandConfiguration(
        commandName: "build-info",
        abstract: "version info from Callisto"
    )

    func run() async throws {
        print("hasUncommitedChanges: \(PackageBuild.info.hasUncommitedChanges)")
        print("           timeStamp: \(PackageBuild.info.timeStamp)")
        print("            timeZone: \(PackageBuild.info.timeZone)")
        print("               count: \(PackageBuild.info.count)")
        print("                 tag: \(PackageBuild.info.tag ?? "none")")
        print("       countSinceTag: \(PackageBuild.info.countSinceTag)")
        print("              branch: \(PackageBuild.info.branch ?? "none")")
        print("              digest: \(PackageBuild.info.digest)")
        print("          moduleName: \(PackageBuild.info.moduleName)")

        print("BuildInfo file: \(PackageBuild._file())")
    }
}
// swiftlint:enable print_usage
