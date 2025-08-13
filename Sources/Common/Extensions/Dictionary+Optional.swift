//
//  Dictionary+Optional.swift
//  clangParser
//
//  Created by Patrick Kladek on 28.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation

public extension Dictionary {

    @discardableResult
    mutating func updateOptionalValue(_ value: Dictionary.Value?, forKey key: Dictionary.Key?) -> Dictionary.Value? {
        guard let key = key else { return nil }
        let oldValue = self[key]
        guard let value = value else { return oldValue }

        self[key] = value

        return oldValue
    }

    subscript(optional key: Dictionary.Key?) -> Dictionary.Value? {
        get {
            guard let key = key else { return nil }
            return self[key]
        }
        set {
            self.updateOptionalValue(newValue, forKey: key)
        }
    }
}

public extension Dictionary where Key: StringProtocol {

    subscript(keyPath keyPath: KeyPath) -> Any? {
        switch keyPath.headAndTail() {
        case nil:
            // key path is empty.
            return nil
        case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
            // Reached the end of the key path.
            let key = Key(string: head)
            return self[key]
        case let (head, remainingKeyPath)?:
            // Key path has a tail we need to traverse.
            let key = Key(string: head)
            switch self[key] {
            case let nestedDict as [Key: Any]:
                // Next nest level is a dictionary.
                // Start over with remaining key path.
                return nestedDict[keyPath: remainingKeyPath]
            default:
                // Next nest level isn't a dictionary.
                // Invalid key path, abort.
                return nil
            }
        }
    }
}

// Needed because Swift 3.0 doesn't support extensions with concrete
// same-type requirements (extension Dictionary where Key == String).
public protocol StringProtocol {
    init(string s: String)
}

extension String: StringProtocol {
    public init(string s: String) {
        self = s
    }
}

public struct KeyPath {
    public var segments: [String]

    public var isEmpty: Bool { return segments.isEmpty }
    public var path: String {
        return segments.joined(separator: ".")
    }

    /// Strips off the first segment and returns a pair
    /// consisting of the first segment and the remaining key path.
    /// Returns nil if the key path has no segments.
    public func headAndTail() -> (head: String, tail: KeyPath)? {
        guard !isEmpty else { return nil }
        var tail = segments
        let head = tail.removeFirst()
        return (head, KeyPath(segments: tail))
    }
}

/// Initializes a KeyPath with a string of the form "this.is.a.keypath"
public extension KeyPath {
    init(_ string: String) {
        segments = string.components(separatedBy: ".")
    }
}

extension KeyPath: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
    public init(unicodeScalarLiteral value: String) {
        self.init(value)
    }
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(value)
    }
}
