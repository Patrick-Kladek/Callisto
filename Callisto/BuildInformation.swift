//
//  CompilerRun.swift
//  Callisto
//
//  Created by Patrick Kladek on 30.07.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


/// Holds all information about a compiler run
struct BuildInformation: Codable {

    let platform: String
    let errors: [CompilerMessage]
    let warnings: [CompilerMessage]
    let unitTests: [UnitTestMessage]


    static let empty = BuildInformation(platform: "",
                                        errors: [],
                                        warnings: [],
                                        unitTests: [])
}
