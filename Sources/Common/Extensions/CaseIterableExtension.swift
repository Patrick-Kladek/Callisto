//
//  CaseIterableExtension.swift
//  analytics-generator
//
//  Created by Patrick Kladek on 18.12.24.
//

import Foundation

extension CaseIterable where Self: Equatable {

    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)! // swiftlint:disable:this force_unwrapping
        let next = all.index(after: idx)
        return all[next == all.endIndex ? all.startIndex : next]
    }

    mutating
    func selectNext() {
        self = self.next()
    }

    static func > (lhs: Self, rhs: Self) -> Bool {
        guard let leftPosition = allCases.firstIndex(of: lhs) else { return false }
        guard let rightPosition = Self.allCases.firstIndex(of: rhs) else { return false }

        return leftPosition > rightPosition
    }

    static func >= (lhs: Self, rhs: Self) -> Bool {
        guard let leftPosition = allCases.firstIndex(of: lhs) else { return false }
        guard let rightPosition = Self.allCases.firstIndex(of: rhs) else { return false }

        return leftPosition >= rightPosition
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        guard let leftPosition = allCases.firstIndex(of: lhs) else { return false }
        guard let rightPosition = Self.allCases.firstIndex(of: rhs) else { return false }

        return leftPosition < rightPosition
    }

    static func <= (lhs: Self, rhs: Self) -> Bool {
        guard let leftPosition = allCases.firstIndex(of: lhs) else { return false }
        guard let rightPosition = Self.allCases.firstIndex(of: rhs) else { return false }

        return leftPosition <= rightPosition
    }
}
