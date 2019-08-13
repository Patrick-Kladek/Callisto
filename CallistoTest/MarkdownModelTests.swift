//
//  MarkdownModelTests.swift
//  CallistoTest
//
//  Created by Patrick Kladek on 09.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import XCTest
import Callisto


class MarkdownModelTests: XCTestCase {

    func testFillToBiggerArray() {
        let array = ["Hello", "World"]
        let filledArray = array.fill(to: 3)
        XCTAssertEqual(filledArray.count, 3)
    }

    func testFillToSamllerArray() {
        let array = ["Hello", "World", "This", "Is", "A", "Test"]
        let filledArray = array.fill(to: 3)
        XCTAssertEqual(filledArray.count, 6)
    }

    func testFillToEqualArray() {
        let array = ["Hello", "World", "This", "Is", "A", "Test"]
        let filledArray = array.fill(to: 6)
        XCTAssertEqual(filledArray.count, 6)
    }

    func testHeaderShorterThanRows() {
        let table = MarkdownTable(header: ["Type", "File", "Message"], rows: [
            ["Warning", "README.md", "Typo in line 243"],
            ["UnitTest", "", "testImageRepresentationWithScaling"],
            ["Hello", "World", "This", "Is", "a", "bigger", "table"]
        ])

        let referenceString =
        """
        | Type | File | Message |  |  |  |  |
        | --- | --- | --- | --- | --- | --- | --- |
        | Warning | README.md | Typo in line 243 |  |  |  |  |
        | UnitTest |  | testImageRepresentationWithScaling |  |  |  |  |
        | Hello | World | This | Is | a | bigger | table |
        """

        XCTAssertEqual(referenceString, table.markdownString)
    }

    func testHeaderLongerThanRows() {
        let table = MarkdownTable(header: ["Type", "File", "Message", "Hint"], rows: [
            ["Warning", "README.md", "Typo in line 243"],
            ["UnitTest", "", "testImageRepresentationWithScaling"],
            ["Hello", "World", "This"]
        ])

        let referenceString =
        """
        | Type | File | Message | Hint |
        | --- | --- | --- | --- |
        | Warning | README.md | Typo in line 243 |  |
        | UnitTest |  | testImageRepresentationWithScaling |  |
        | Hello | World | This |  |
        """

        XCTAssertEqual(referenceString, table.markdownString)
    }

    func testHeaderEqualRows() {
        let table = MarkdownTable(header: ["Type", "File", "Message"], rows: [
            ["Warning", "README.md", "Typo in line 243"],
            ["UnitTest", "", "testImageRepresentationWithScaling"],
            ["Hello", "World", "This"]
        ])

        let referenceString =
        """
        | Type | File | Message |
        | --- | --- | --- |
        | Warning | README.md | Typo in line 243 |
        | UnitTest |  | testImageRepresentationWithScaling |
        | Hello | World | This |
        """

        XCTAssertEqual(referenceString, table.markdownString)
    }
}
