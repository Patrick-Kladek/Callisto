//
//  Title.swift
//  MarkdownKit
//
//  Created by Patrick Kladek on 16.11.21.
//

import Foundation

public struct Title: MarkdownConformable {

    public enum Header: Int {
        case h1 = 1
        case h2
        case h3
        case h4
        case h5
        case h6
    }

    let title: String
    let header: Header

    public init(_ title: String, header: Header = .h1) {
        self.title = title
        self.header = header
    }

    public var lines: [String] {
        let line = (1...self.header.rawValue).reduce("") { partialResult, _ in
            return partialResult + "#"
        } + " \(self.title)"
        return [line]
    }
}
