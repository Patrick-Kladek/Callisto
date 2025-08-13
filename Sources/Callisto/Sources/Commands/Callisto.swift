//
//  Callisto.swift
//  Callisto
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import ArgumentParser

@main
struct Callisto: AsyncParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool to parse fastlane build output",
        version: PackageBuild.info.describe,
        subcommands: [DependenciesCommand.self, SummariseCommand.self, PostGithubCommand.self, PostSlackCommand.self, FailBuildCommand.self, BuildInfoCommand.self])

    init() { }
}
