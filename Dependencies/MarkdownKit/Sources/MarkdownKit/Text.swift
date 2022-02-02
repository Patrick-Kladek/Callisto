//
//  Text.swift
//  MarkdownKit
//
//  Created by Patrick Kladek on 16.11.21.
//

import Foundation

public struct Text: MarkdownConformable {

    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var lines: [String] {
        return [self.text]
    }
}
