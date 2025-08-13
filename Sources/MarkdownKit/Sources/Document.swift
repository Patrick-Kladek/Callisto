//
//  Document.swift
//  MarkdownKit
//
//  Created by Patrick Kladek on 16.11.21.
//

import Foundation

public struct Document {

    private(set) var components: [MarkdownConformable] = []

    public mutating func addComponent(_ component: MarkdownConformable) {
        self.components.append(component)
    }

    public init() { }

    public func text() -> String {
        return self.lines.joined(separator: "\n")
    }
}

// MARK: - MarkdownConformable

extension Document: MarkdownConformable {

    public var lines: [String] {
        return self.components.flatMap { $0.lines }
    }
}
