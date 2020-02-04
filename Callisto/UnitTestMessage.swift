//
//  UnitTestMessage.swift
//  Callisto
//
//  Created by Patrick Kladek on 07.06.17.
//  Copyright © 2017 IdeasOnCanvas. All rights reserved.
//

import Cocoa

final class UnitTestMessage: Codable {

    let method: String
    let assertType: String
    let explanation: String

    init?(message: String) {
        guard let xRange = (message.range(of: "✗")) else { return nil }

        let validMessage = message[xRange.lowerBound...]
        let components = validMessage.components(separatedBy: CharacterSet(charactersIn: ",-"))
        guard components.count >= 3 else { return nil }

        self.method = String(components[0].dropFirst(2))
        self.assertType = components[1].trim()
        self.explanation = components[2].trim().strippingLocalInfos.condenseWhitespace()
    }
}

extension UnitTestMessage: CustomStringConvertible {

    var description: String {
        return "\(self.method), \(self.assertType) - \(self.explanation)"
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

private extension String {

    /// Deletes informations like: <__NSArrayM: 0x60000184dfb0>
    /// Before: "*** Collection <__NSArrayM: 0x60000184dfb0> was mutated while being enumerated."
    /// After "*** Collection was mutated while being enumerated."
    var strippingLocalInfos: String {
        return self.trim(from: "<", to: ">")
    }
}
