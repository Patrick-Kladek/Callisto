//
//  EmptyLine.swift
//  MarkdownKit
//
//  Created by Patrick Kladek on 16.11.21.
//

import Foundation

public struct EmptyLine: MarkdownConformable {

    public var lines: [String] {
        return [""]
    }

    public init() { }
}
