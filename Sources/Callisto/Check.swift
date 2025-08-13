//
//  Check.swift
//  Callisto
//
//  Created by Patrick Kladek on 08.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation

struct Check: Codable {

    enum Status: String, Codable {
        case queued = "queued"
        case inProgress = "in_progress"
        case completed = "completed"
    }

    let name: String
    let headSHA: String
    let details: URL
    let id: String
    let status: Status
    let startedAt: Date
    let conclusion: String
    let completedAt: Date
    let output: Output

    enum CodingKeys: String, CodingKey {
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
}
