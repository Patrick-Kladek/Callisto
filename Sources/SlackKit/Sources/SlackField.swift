//
//  SlackField.swift
//  clangParser
//
//  Created by Patrick Kladek on 27.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation
import Common

public class SlackField {

    public let title: String
    public let value: String
    public let shortened: Bool

    public init(title: String, value: String, shortened: Bool = false) {
        self.title = title
        self.value = value
        self.shortened = shortened
    }
}

extension SlackField: DictionaryConvertable {

    public func dictionaryRepresentation() -> [String: Any] {
        return [
            "title": self.title,
            "value": self.value,
            "short": self.shortened
        ]
    }
}
