//
//  SlackAction.swift
//  clangParser
//
//  Created by Patrick Kladek on 27.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation
import Common

public class SlackAction {

    public let name: String
    public let text: String
    public let type: String
    public let value: String
    public let style: String?
    public var confirm: SlackActionConfirm?

    public static func makeDangerAction(name: String, text: String, type: String, value: String) -> SlackAction {
        return SlackAction(name: name, text: text, type: type, value: value, style: "danger")
    }

    public init(name: String, text: String, type: String, value: String, style: String? = nil) {
        self.name = name
        self.text = text
        self.type = type
        self.value = value
        self.style = style
    }

    public func addConfirmDialogue(title: String, text: String, proceedText: String, dismissText: String) {
        self.confirm = SlackActionConfirm(title: title, text: text, proceedText: proceedText, dismissText: dismissText)
    }
}

extension SlackAction: DictionaryConvertable {

    public func dictionaryRepresentation() -> [String: Any] {
        var dict: [String: Any] = [
            "name": self.name,
            "text": self.text,
            "type": self.type,
            "value": self.value
        ]

        if let confirm = self.confirm?.dictionaryRepresentation() {
            dict["confirm"] = confirm
        }

        return dict
    }
}

public class SlackActionConfirm {

    public let title: String
    public let text: String
    public let proceedText: String
    public let dismissText: String

    public init(title: String, text: String, proceedText: String, dismissText: String) {
        self.title = title
        self.text = text
        self.proceedText = proceedText
        self.dismissText = dismissText
    }
}

extension SlackActionConfirm: DictionaryConvertable {

    public func dictionaryRepresentation() -> [String: Any] {
        return [
            "title": self.title,
            "text": self.text,
            "ok_text": self.proceedText,
            "dismiss_text": self.dismissText
        ]
    }
}
