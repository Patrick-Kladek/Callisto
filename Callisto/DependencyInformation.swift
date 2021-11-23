//
//  DependencyInformation.swift
//  Callisto
//
//  Created by Patrick Kladek on 23.11.21.
//  Copyright © 2021 IdeasOnCanvas. All rights reserved.
//

import Foundation

struct DependencyInformation: Codable {

    let outdated: [Dependency]
    let ignored: [Dependency]
}
