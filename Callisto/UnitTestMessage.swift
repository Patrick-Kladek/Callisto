//
//  UnitTestMessage.swift
//  Callisto
//
//  Created by Patrick Kladek on 07.06.17.
//  Copyright © 2017 IdeasOnCanvas. All rights reserved.
//

import Cocoa

final class UnitTestMessage {

    let method: String
    let assertType: String
    let explanation: String

    init?(message: String) {
        guard let xRange = (message.range(of: "✗")) else { return nil }

        let validMessage = message[xRange.lowerBound...]
        let components = validMessage.components(separatedBy: CharacterSet(charactersIn: ",-"))
        guard components.count >= 3 else { return nil }

        self.method = components[0]
        self.assertType = components[1]
        self.explanation = components[2]
    }
}

extension UnitTestMessage: CustomStringConvertible {

    var description: String {
        return self.method
    }
}

extension UnitTestMessage: Hashable {

    static func == (left: UnitTestMessage, right: UnitTestMessage) -> Bool {
        return
            left.method == right.method &&
            left.assertType == right.assertType &&
            left.explanation == right.explanation
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.method)
        hasher.combine(self.assertType)
        hasher.combine(self.explanation)
    }
}
