//
//  SlackMessage.swift
//  clangParser
//
//  Created by Patrick Kladek on 27.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

class SlackMessage {

    let text: String
    private(set) var attachments: [SlackAttachment] = []

    init(text: String = "", attachments: [SlackAttachment] = []) {
        self.text = text
        self.attachments = attachments
    }

    func add(attachment: SlackAttachment) {
        self.attachments.append(attachment)
    }

    func jsonDataRepresentation() -> Data? {
        return try? JSONSerialization.data(withJSONObject: self.dictionaryRepresentation(), options: [])
    }
}

extension SlackMessage: DictionaryConvertable {

    func dictionaryRepresentation() -> [String: Any] {
        var dict: [String: Any] = [:]

        dict["text"] = self.text
        dict[optional: "attachments"] = self.attachments.map { $0.dictionaryRepresentation() }

        return dict
    }
}
