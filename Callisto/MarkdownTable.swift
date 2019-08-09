//
//  MarkdownTable.swift
//  Callisto
//
//  Created by Patrick Kladek on 09.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


struct MarkdownTable {
    let header: [String]
    let rows: [[String]]
}

extension MarkdownTable {

    var markdownString: String {
        let columns = max(self.header.count, self.rows.map { $0.count }.max() ?? 0)
        let formattedTable = MarkdownTable(header: self.header.fill(to: columns),
                                           rows: self.rows.map { $0.fill(to: columns) })

        var message: String = ""
        message += formattedTable.header.markdownTableRow + "\n"

        for _ in 0 ... (columns - 1) {
            message += "| --- "
        }
        message += "|"

        for row in formattedTable.rows {
            message += "\n" + row.markdownTableRow
        }

        return message
    }
}

extension Array where Element == String {

    func fill(to length: Int) -> Array<Element> {
        guard self.count < length else { return self }

        var array = self

        for _ in self.count ... (length - 1) {
            array.append(Element())
        }

        return array
    }

    var markdownTableRow: String {
        return "| " + self.joined(separator: " | ") + " |"
    }
}
