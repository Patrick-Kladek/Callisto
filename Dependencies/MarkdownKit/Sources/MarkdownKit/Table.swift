//
//  Table.swift
//  MarkdownKit
//
//  Created by Patrick Kladek on 16.11.21.
//

import Foundation

public struct Table {

    public struct Row {
        public typealias Column = String

        public let columns: [Column]

        public init(columns: [Column]) {
            self.columns = columns
        }

        public var longestColumn: Int {
            return self.columns.reduce(Int.min) { max($0, $1.count) }
        }

        public func line(equalWidth width: Int) -> String {
            let elements = self.columns.map {
                $0.padding(toLength: width, withPad: " ", startingAt: 0)
            }
            return "| " + elements.joined(separator: " | ") + " |"
        }

        public func separatorLine(width: Int) -> String {
            let elements = repeatElement("".padding(toLength: width, withPad: "-", startingAt: 0), count: self.columns.count)
            return "| " + elements.joined(separator: " | ") + " |"
        }
    }

    private let titleRow: Row
    private var rows: [Row] = []

    // MARK: - Lifecycle

    public
    init(titles: Row) {
        self.titleRow = titles
    }

    public
    mutating func addRow(_ row: Row) {
        self.rows.append(row)
    }

    public
    mutating func addRows(_ rows: [Row]) {
        self.rows.append(contentsOf: rows)
    }
}

// MARK: - MarkdownConformable

extension Table: MarkdownConformable {

    public var lines: [String] {
        let width = self.longestColumn
        var lines: [String] = []
        lines.append(self.titleRow.line(equalWidth: width))
        lines.append(self.titleRow.separatorLine(width: width))

        for row in self.rows {
            lines.append(row.line(equalWidth: width))
        }

        return lines
    }
}

// MARK: - Private

private extension Table {

    var longestColumn: Int {
        var width = self.titleRow.longestColumn
        for row in self.rows {
            width = max(row.longestColumn, width)
        }
        return width
    }
}
