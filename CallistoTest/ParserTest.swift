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

        if case .success(let code) = parser.parse() {
            XCTAssertEqual(code, 65)
        } else {
            XCTFail()
        }

        XCTAssertEqual(parser.buildErrorMessages.count, 0)
        XCTAssertEqual(parser.staticAnalyzerMessages.count, 0)
        XCTAssertEqual(parser.unitTestMessages.count, 4)
    }

    func testFastlaneDesktopParser() {
        guard let fastlaneOutputURL = Bundle.init(for: type(of: self)).url(forResource: "mac_build_4454", withExtension: "log") else { XCTFail(); return; }
        guard let fastlaneContent = try? String.init(contentsOf: fastlaneOutputURL, encoding: .utf8) else { XCTFail(); return; }

        let parser = FastlaneParser(content: fastlaneContent, ignoredKeywords: ["todo"])

        if case .success(let code) = parser.parse() {
            XCTAssertEqual(code, 65)
        } else {
            XCTFail()
        }

        XCTAssertEqual(parser.buildErrorMessages.count, 2) 
        XCTAssertEqual(parser.staticAnalyzerMessages.count, 0)
        XCTAssertEqual(parser.unitTestMessages.count, 0)
    }

    func testIgnoreFile() {
        guard let fastlaneOutputURL = Bundle.init(for: type(of: self)).url(forResource: "ios_build_4822", withExtension: "log") else { XCTFail(); return; }
        guard let fastlaneContent = try? String.init(contentsOf: fastlaneOutputURL, encoding: .utf8) else { XCTFail(); return; }

        let parser = FastlaneParser(content: fastlaneContent, ignoredKeywords: ["BITCrashManager", "todo"])

        if case .success(let code) = parser.parse() {
            XCTAssertEqual(code, -1)
        } else {
            XCTFail()
        }

        print(parser.buildErrorMessages)
        print(parser.staticAnalyzerMessages)
        print(parser.unitTestMessages)
    }

    func testXcode9_3_MobileParser() {
        guard let fastlaneOutputURL = Bundle.init(for: type(of: self)).url(forResource: "ios_build_8745", withExtension: "log") else { XCTFail(); return; }
        guard let fastlaneContent = try? String.init(contentsOf: fastlaneOutputURL, encoding: .utf8) else { XCTFail(); return; }

        let parser = FastlaneParser(content: fastlaneContent, ignoredKeywords: ["todo"])

        if case .success(let code) = parser.parse() {
            XCTAssertEqual(code, 65)
        } else {
            XCTFail()
        }

        XCTAssertEqual(parser.buildErrorMessages.count, 1)
        XCTAssertEqual(parser.staticAnalyzerMessages.count, 10)
        XCTAssertEqual(parser.unitTestMessages.count, 0)
    }

    func testXcode9_3_DesktopParser() {
        guard let fastlaneOutputURL = Bundle.init(for: type(of: self)).url(forResource: "mac_build_8745", withExtension: "log") else { XCTFail(); return; }
        guard let fastlaneContent = try? String.init(contentsOf: fastlaneOutputURL, encoding: .utf8) else { XCTFail(); return; }

        let parser = FastlaneParser(content: fastlaneContent, ignoredKeywords: ["todo"])

        if case .success(let code) = parser.parse() {
            XCTAssertEqual(code, -1)
        } else {
            XCTFail()
        }

        XCTAssertEqual(parser.buildErrorMessages.count, 0)
        XCTAssertEqual(parser.staticAnalyzerMessages.count, 6)
        XCTAssertEqual(parser.unitTestMessages.count, 0)
    }
}
