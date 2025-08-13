//
//  GithubModelTests.swift
//  CallistoTest
//
//  Created by Patrick Kladek on 08.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import XCTest
@testable import Callisto

class GithubModelTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAnnotation() {
        let annotation = Annotation(path: "README.md",
                                    startLine: 2,
                                    endLine: 2,
                                    level: .warning,
                                    message: "Check your spelling for 'banaas'.",
                                    title: "Spell Checker",
                                    details: "Do you mean 'bananas' or 'banana'?")

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try! encoder.encode(annotation)
        let string = String(data: data, encoding: .utf8)

        let referenceString =
        """
        {
          "title" : "Spell Checker",
          "message" : "Check your spelling for 'banaas'.",
          "annotation_level" : "warning",
          "start_line" : 2,
          "path" : "README.md",
          "raw_details" : "Do you mean 'bananas' or 'banana'?",
          "end_line" : 2
        }
        """

        XCTAssertEqual(string, referenceString)
    }

/*
{
    "path": "README.md",
    "annotation_level": "warning",
    "title": "Spell Checker",
    "message": "Check your spelling for 'banaas'.",
    "raw_details": "Do you mean 'bananas' or 'banana'?",
    "start_line": 2,
    "end_line": 2
},


 {
   "annotation_level" : "warning",
   "end_line" : 2,
   "message" : "Check your spelling for 'banaas'.",
   "path" : "README.md",
   "raw_details" : "Do you mean 'bananas' or 'banana'?",
   "start_line" : 2,
   "title" : "Spell Checker"
 }
 */
}
