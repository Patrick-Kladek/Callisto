//
//  SlackAttachment.swift
//  clangParser
//
//  Created by Patrick Kladek on 27.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

enum SlackAttachmentType: String {
    case good
    case warning
    case danger
}

class SlackAttachment {

    var title: String?
    var text: String?
    var preText: String?

    var authorName: String?
    var authorIcon: URL?
    var authorURL: URL?
    var imageURL: URL?
    var titleURL: URL?
    var thumbURL: URL?

    var fallback: String?
    var callback_id: String?
    var colorHex: String?
    var attachment_type: String?

    var footer: String?
    var footerIcon: URL?
    var timeStamp: Date?

    var fields: [SlackField] = []
    var actions: [SlackAction] = []

    init(type: SlackAttachmentType) {
        self.colorHex = type.rawValue
    }

    func addField(_ field: SlackField) {
        self.fields.append(field)
    }

    func setColor(_ color: NSColor) {
        self.colorHex = color.hexValue()
    }
}

extension SlackAttachment: DictionaryConvertable {

    func dictionaryRepresentation() -> [String: Any] {
        var dict: [String: Any] = [:]

        dict[optional: "fallback"] = self.fallback
        dict[optional: "color"] = self.colorHex
        dict[optional: "pretext"] = self.preText
        dict[optional: "author_name"] = self.authorName
        dict[optional: "author_link"] = self.authorURL?.absoluteString
        dict[optional: "author_icon"] = self.authorIcon?.absoluteString
        dict[optional: "title"] = self.title
        dict[optional: "title_link"] = self.titleURL?.absoluteString
        dict[optional: "text"] = self.text
        dict[optional: "fields"] = self.fields.map { $0.dictionaryRepresentation() }
        dict[optional: "image_url"] = self.imageURL?.absoluteString
        dict[optional: "thumb_url"] = self.thumbURL?.absoluteString
        dict[optional: "footer"] = self.footer
        dict[optional: "footer_icon"] = self.footerIcon
        dict[optional: "ts"] = self.timeStamp != nil ? String(format: "%f", self.timeStamp!.timeIntervalSince1970) : nil

        return dict
    }
}
