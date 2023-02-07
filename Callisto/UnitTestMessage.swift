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
    let assertType: String?
    let explanation: String?

    init?(message: String) {
        guard let xRange = (message.range(of: "✖")) ?? (message.range(of: "✔")) else { return nil }

        let validMessage = message[xRange.lowerBound...]
        let components = validMessage.components(separatedBy: CharacterSet(charactersIn: ",-"))

        if components.count >= 3  {
            self.method = String(components[0].dropFirst(2))
            self.assertType = components[1].trim()
            self.explanation = components[2].trim().strippingLocalInfos.condenseWhitespace()
        } else {
            self.method = String(components[0].dropFirst(2)).components(separatedBy: " ")[0]
            self.assertType = nil
            self.explanation = nil
        }
    }
}

extension UnitTestMessage: CustomStringConvertible {

    var description: String {
        if let assertType = self.assertType,
           let explanation = self.explanation {
            return "\(self.method), \(assertType) - \(explanation)"
        }
        return "\(self.method)"
    }
}

extension UnitTestMessage: Hashable {

    static func == (left: UnitTestMessage, right: UnitTestMessage) -> Bool {
        return
            left.method == right.method
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(self.method)
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
