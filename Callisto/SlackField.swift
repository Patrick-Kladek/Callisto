//
//  SlackField.swift
//  clangParser
//
//  Created by Patrick Kladek on 27.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation

class SlackField {

    let title: String
    let value: String
    let shortened: Bool

    init(title: String, value: String, shortened: Bool = false) {
        self.title = title
        self.value = value
        self.shortened = shortened
    }

    convenience init(message: CompilerMessage) {
        let title = "\(message.file) [Line: \(message.line)]"
        self.init(title: title, value: message.message)
    }

    convenience init(message: UnitTestMessage) {
        self.init(title: "\(message.method)", value: "\(message.assertType ?? "")\n\(message.explanation ?? "")")
    }
}

extension SlackField: DictionaryConvertable {

    func dictionaryRepresentation() -> [String: Any] {
        return [
            "title": self.title,
            "value": self.value,
            "short": self.shortened
        ]
    }
}
