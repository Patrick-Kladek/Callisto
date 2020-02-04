//
//  SlackCommunicationTests.swift
//  CallistoTest
//
//  Created by Patrick Kladek on 12.01.18.
//  Copyright © 2018 IdeasOnCanvas. All rights reserved.
//

import XCTest


class SlackCommunicationTests: XCTestCase {

    func testBasicMessage() {
        let message = SlackMessage(text: "Hello World", attachments: [])

        self.send(message)
    }

    func testAttachment() {
        let attachment = SlackAttachment(type: .good)
        attachment.text = "I'm an attachment"
        attachment.fields.append(SlackField(title: "I'm a Field", value: "This is my Value"))
        let message = SlackMessage(text: "", attachments: [attachment])

        self.send(message)
    }
}


private extension SlackCommunicationTests {

    func settingsDictionary() -> [String: String] {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "githubSettings", withExtension: "plist") else { XCTFail(); fatalError() }

        return NSDictionary(contentsOf: url) as? [String: String] ?? [:]
    }

    func communicationController() -> SlackCommunicationController {
        let settings = self.settingsDictionary()
        let url =  URL(string: settings["slackURL"]!)!

        return SlackCommunicationController(url: url)
    }

    @discardableResult
    func send(_ message: SlackMessage, file: StaticString = #file, line: UInt = #line) -> Bool {
        let communicationController = self.communicationController()
        guard let data = try? JSONSerialization.data(withJSONObject: message.dictionaryRepresentation(), options: .prettyPrinted) else { XCTFail("Error Serializing Message", file: file, line: line); return false }

        communicationController.post(data: data)
        return true
    }
}
