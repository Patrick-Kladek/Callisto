//
//  Annotation.swift
//  Callisto
//
//  Created by Patrick Kladek on 08.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


struct Annotation: Codable {

    enum Level: String, Codable {
        case notice
        case warning
        case failure
    }

    let path: String
    let startLine: Int
    let endLine: Int
    let level: Level
    let message: String
    let title: String?
    let details: String?

    enum CodingKeys: String, CodingKey {
        case path
        case startLine = "start_line"
        case endLine = "end_line"
        case level = "annotation_level"
        case message
        case title
        case details = "raw_details"
    }
}
