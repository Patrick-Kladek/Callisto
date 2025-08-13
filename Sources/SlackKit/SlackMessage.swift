//
//  SlackMessage.swift
//  clangParser
//
//  Created by Patrick Kladek on 27.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa
import Common

public class SlackMessage {

    public let text: String
    public private(set) var attachments: [SlackAttachment] = []

    public init(text: String = "", attachments: [SlackAttachment] = []) {
        self.text = text
        self.attachments = attachments
    }

    public func add(attachment: SlackAttachment) {
        self.attachments.append(attachment)
    }

    public func jsonDataRepresentation() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self.dictionaryRepresentation(), options: [])
    }
}

extension SlackMessage: DictionaryConvertable {

    public func dictionaryRepresentation() -> [String: Any] {
        var dict: [String: Any] = [:]

        dict["text"] = self.text
        dict[optional: "attachments"] = self.attachments.map { $0.dictionaryRepresentation() }

        return dict
    }
}
