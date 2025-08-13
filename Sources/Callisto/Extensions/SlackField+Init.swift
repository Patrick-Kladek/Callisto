//
//  SlackField+Init.swift
//  Callisto
//
//  Created by Patrick Kladek on 13.08.25.
//

import SlackKit

extension SlackField {

    convenience init(message: CompilerMessage) {
        let title = "\(message.file) [Line: \(message.line)]"
        self.init(title: title, value: message.message)
    }

    convenience init(message: UnitTestMessage) {
        self.init(title: "\(message.method)", value: "\(message.assertType)\n\(message.explanation)")
    }
}
