//
//  Annotation.swift
//  Callisto
//
//  Created by Patrick Kladek on 08.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation

public struct Annotation: Codable {

    public enum Level: String, Codable {
        case notice
        case warning
        case failure
    }

    public let path: String
    public let startLine: Int
    public let endLine: Int
    public let level: Level
    public let message: String
    public let title: String?
    public let details: String?

    public enum CodingKeys: String, CodingKey {
        case path
        case startLine = "start_line"
        case endLine = "end_line"
        case level = "annotation_level"
        case message
        case title
        case details = "raw_details"
    }

    public init(path: String, startLine: Int, endLine: Int, level: Level, message: String, title: String?, details: String?) {
        self.path = path
        self.startLine = startLine
        self.endLine = endLine
        self.level = level
        self.message = message
        self.title = title
        self.details = details
    }
}
