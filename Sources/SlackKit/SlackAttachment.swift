//
//  SlackAttachment.swift
//  clangParser
//
//  Created by Patrick Kladek on 27.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa
import Common

public enum SlackAttachmentType: String {
    case good
    case warning
    case danger
}

public class SlackAttachment {

    public var title: String?
    public var text: String?
    public var preText: String?

    public var authorName: String?
    public var authorIcon: URL?
    public var authorURL: URL?
    public var imageURL: URL?
    public var titleURL: URL?
    public var thumbURL: URL?

    public var fallback: String?
    public var callbackIdentifier: String?
    public var colorHex: String?
    public var attachmentType: String?

    public var footer: String?
    public var footerIcon: URL?
    public var timeStamp: Date?

    public var fields: [SlackField] = []
    public var actions: [SlackAction] = []

    public init(type: SlackAttachmentType) {
        self.colorHex = type.rawValue
    }

    public func addField(_ field: SlackField) {
        self.fields.append(field)
    }

    public func setColor(_ color: NSColor) {
        self.colorHex = color.hexValue()
    }
}

extension SlackAttachment: DictionaryConvertable {

    public func dictionaryRepresentation() -> [String: Any] {
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
