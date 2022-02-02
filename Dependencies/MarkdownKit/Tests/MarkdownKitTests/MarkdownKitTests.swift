//
//  MarkdownKitTests.swift
//  MarkdownKit
//
//  Created by Patrick Kladek on 16.11.21.
//

import XCTest
@testable import MarkdownKit


final class MarkdownKitTests: XCTestCase {

    func testTitle() throws {
        let title = Title("Hello World", header: .h4)
        let lines = title.lines
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0], "#### Hello World")
    }

    func testText() throws {
        let text = Text("Hello World")
        let lines = text.lines
        XCTAssertEqual(lines.count, 1)
        XCTAssertEqual(lines[0], "Hello World")
    }

    func testTable() throws {
        var table = Table(titles: Table.Row(columns: ["Library", "Current", "New"]))
        table.addRow(Table.Row(columns: ["Alamofire", "2.1.0", "3.0.0"]))

        let text = table.lines.joined(separator: "\n")
        let expected =
        """
        | Library   | Current   | New       |
        | --------- | --------- | --------- |
        | Alamofire | 2.1.0     | 3.0.0     |
        """

        XCTAssertEqual(text, expected)
    }

    func testDocument() throws {
        var doc = Document()
        doc.addComponent(Title("New Version Available", header: .h3))
        doc.addComponent(EmptyLine())

        var table = Table(titles: Table.Row(columns: ["Library", "Current", "New"]))
        table.addRow(Table.Row(columns: ["Alamofire", "2.1.0", "3.0.0"]))
        doc.addComponent(table)

        let lines = doc.lines
        let text = doc.text()
        let expected =
        """
        ### New Version Available

        | Library   | Current   | New       |
        | --------- | --------- | --------- |
        | Alamofire | 2.1.0     | 3.0.0     |
        """

        XCTAssertEqual(lines.count, 5)
        XCTAssertEqual(text, expected)
    }
}
