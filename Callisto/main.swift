//
//  main.swift
//  clangParser
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import ArgumentParser

struct Callisto: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A Swift command-line tool to Parse Fastlane Build Output",
        subcommands: [Summarise.self, Upload.self])

    init() { }
}

final class Generate: ParsableCommand {

    public static let configuration = CommandConfiguration(abstract: "Generate a blog post banner from the given input")

    @Argument(help: "The title of the blog post")
    private var title: String

    @Option(name: .shortAndLong, help: "The week of the blog post as used in the file name")
    private var week: Int?

    @Flag(name: .shortAndLong, help: "Show all roll results.")
    private var verbose

    func run() throws {
        let weekDescription = week.map { "and week \($0)" }
        print("Creating a banner for title \"\(title)\" \(weekDescription ?? "")")
    }
}

struct Upload: ParsableCommand {
    public static let configuration = CommandConfiguration(abstract: "Upload blog post banner from the given input")

    func run() throws {
        print("Run")
    }
}


Callisto.main()
