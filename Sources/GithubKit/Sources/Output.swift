//
//  Output.swift
//  Callisto
//
//  Created by Patrick Kladek on 08.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation

public struct Output: Codable {

    public let title: String
    public let summary: String
    public let annotations: [Annotation]
    public let text: String?

    public init(title: String, summary: String, annotations: [Annotation], text: String?) {
        self.title = title
        self.summary = summary
        self.annotations = annotations
        self.text = text
    }
}
