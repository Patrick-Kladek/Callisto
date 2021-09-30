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

Callisto.main()
