//
//  CallistoTest.swift
//  CallistoTest
//
//  Created by Patrick Kladek on 07.06.17.
//  Copyright © 2017 IdeasOnCanvas. All rights reserved.
//

import XCTest


class CallistoTest: XCTestCase {
    
    func testFastlaneMobileParser() {
        guard let fastlaneOutputURL = Bundle.init(for: type(of: self)).url(forResource: "ios_build_4454", withExtension: "log") else { XCTFail(); return; }
        guard let fastlaneContent = try? String.init(contentsOf: fastlaneOutputURL, encoding: .utf8) else { XCTFail(); return; }

        let parser = FastlaneParser(content: fastlaneContent, ignoredKeywords: ["todo"])
        XCTAssertEqual(65, parser.parse())

        XCTAssertEqual(parser.buildSummary.errors.count, 0)
        XCTAssertEqual(parser.buildSummary.warnings.count, 0)
        XCTAssertEqual(parser.buildSummary.unitTests.count, 4)
    }

    func testFastlaneDesktopParser() {
        guard let fastlaneOutputURL = Bundle.init(for: type(of: self)).url(forResource: "mac_build_4454", withExtension: "log") else { XCTFail(); return; }
        guard let fastlaneContent = try? String.init(contentsOf: fastlaneOutputURL, encoding: .utf8) else { XCTFail(); return; }

        let parser = FastlaneParser(content: fastlaneContent, ignoredKeywords: ["todo"])
        XCTAssertEqual(65, parser.parse())

        XCTAssertEqual(parser.buildSummary.errors.count, 2)
        XCTAssertEqual(parser.buildSummary.warnings.count, 0)
        XCTAssertEqual(parser.buildSummary.unitTests.count, 0)
    }

    func testIgnoreFile() {
        guard let fastlaneOutputURL = Bundle.init(for: type(of: self)).url(forResource: "ios_build_4822", withExtension: "log") else { XCTFail(); return; }
        guard let fastlaneContent = try? String.init(contentsOf: fastlaneOutputURL, encoding: .utf8) else { XCTFail(); return; }

        let parser = FastlaneParser(content: fastlaneContent, ignoredKeywords: ["BITCrashManager", "todo"])
        XCTAssertEqual(-1, parser.parse())

        print(parser.buildSummary.errors.count)
        print(parser.buildSummary.warnings.count)
        print(parser.buildSummary.unitTests.count)
    }

    func testXcode9_3_MobileParser() {
        guard let fastlaneOutputURL = Bundle.init(for: type(of: self)).url(forResource: "ios_build_8745", withExtension: "log") else { XCTFail(); return; }
        guard let fastlaneContent = try? String.init(contentsOf: fastlaneOutputURL, encoding: .utf8) else { XCTFail(); return; }

        let parser = FastlaneParser(content: fastlaneContent, ignoredKeywords: ["todo"])
        XCTAssertEqual(65, parser.parse())

        XCTAssertEqual(parser.buildSummary.errors.count, 0)
        XCTAssertEqual(parser.buildSummary.warnings.count, 9)
        XCTAssertEqual(parser.buildSummary.unitTests.count, 1)
    }

    func testXcode9_3_DesktopParser() {
        guard let fastlaneOutputURL = Bundle.init(for: type(of: self)).url(forResource: "mac_build_8745", withExtension: "log") else { XCTFail(); return; }
        guard let fastlaneContent = try? String.init(contentsOf: fastlaneOutputURL, encoding: .utf8) else { XCTFail(); return; }

        let parser = FastlaneParser(content: fastlaneContent, ignoredKeywords: ["todo"])
        XCTAssertEqual(65, parser.parse())

        XCTAssertEqual(parser.buildSummary.errors.count, 0)
        XCTAssertEqual(parser.buildSummary.warnings.count, 6)
        XCTAssertEqual(parser.buildSummary.unitTests.count, 1)
    }
}
