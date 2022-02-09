//
//  FailBuildAction.swift
//  Callisto
//
//  Created by Ammad on 03/02/2022.
//  Copyright © 2022 IdeasOnCanvas. All rights reserved.
//

import Foundation
import ArgumentParser

// MARK: - FailBuildAction
final class FailBuildAction: ParsableCommand {
    @Argument(help: "Location for .json file", completion: .file(), transform: URL.init(fileURLWithPath:))
    var files: [URL] = []
}

// MARK: - Extension
extension FailBuildAction {
    func run() throws {
    }
}
