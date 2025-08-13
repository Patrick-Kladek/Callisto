//
//  Check.swift
//  Callisto
//
//  Created by Patrick Kladek on 08.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation

public struct Check: Codable {

    public enum Status: String, Codable {
        case queued = "queued"
        case inProgress = "in_progress"
        case completed = "completed"
    }

    public let name: String
    public let headSHA: String
    public let details: URL
    public let id: String
    public let status: Status
    public let startedAt: Date
    public let conclusion: String
    public let completedAt: Date
    public let output: Output

    public enum CodingKeys: String, CodingKey {
        case name
        case headSHA = "head_sha"
        case details = "details_url"
        case id = "external_id"
        case status
        case startedAt = "started_at"
        case conclusion
        case completedAt = "completed_at"
        case output
    }

    public init(name: String, headSHA: String, details: URL, id: String, status: Status, startedAt: Date, conclusion: String, completedAt: Date, output: Output) {
        self.name = name
        self.headSHA = headSHA
        self.details = details
        self.id = id
        self.status = status
        self.startedAt = startedAt
        self.conclusion = conclusion
        self.completedAt = completedAt
        self.output = output
    }
}
