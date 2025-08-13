//
//  Comment.swift
//  Callisto
//
//  Created by Patrick Kladek on 08.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation

public struct Comment: Codable {
    public let body: String
    public let id: Int?

    public init(body: String, id: Int?) {
        self.body = body
        self.id = id
    }
}
