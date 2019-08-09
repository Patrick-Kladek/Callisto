//
//  Output.swift
//  Callisto
//
//  Created by Patrick Kladek on 08.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


struct Output: Codable {

    let title: String
    let summary: String
    let annotations: [Annotation]
    let text: String?
}
