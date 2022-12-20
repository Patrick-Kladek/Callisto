//
//  File.swift
//  
//
//  Created by Patrick Kladek on 20.12.22.
//

import Foundation

public struct Link: MarkdownConformable {

    let title: String
    let url: URL

    public init(_ title: String, url: URL) {
        self.title = title
        self.url = url
    }

    public var lines: [String] {
        let line = "[\(self.title)](\(self.url.absoluteString))"
        return [line]
    }
}

