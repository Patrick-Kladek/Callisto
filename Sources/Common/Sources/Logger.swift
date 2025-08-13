//
//  Logger.swift
//  analytics-generator
//
//  Created by Patrick Kladek on 11.12.24.
//

import Foundation

// MARK: - LoggerInfo

public final class LoggerInfo: @unchecked Sendable {

    // MARK: Nested Types

    /// Log types and their associated ANSI color codes.
    public enum LogLevel: String, CaseIterable, Equatable, Hashable {
        case verbose = "⇂"
        case info = ""
        case success = "✓"
        case warning = "⚠"
        case error = "✘"

        // MARK: Functions

        /// Returns the colored log level string.
        func coloredLogLevel() -> String? {
            let color: String
            switch self {
            case .verbose: color = "\u{001B}[36m" // Cyan
            case .info: return nil // Info
            case .success: color = "\u{001B}[32m" // Green
            case .warning: color = "\u{001B}[33m" // Yellow
            case .error: color = "\u{001B}[31m" // Red
            }
            return "\(color)\(self.rawValue.uppercased())\u{001B}[0m"
        }
    }

    // MARK: Static Properties

    public static let shared = LoggerInfo()

    // MARK: Properties

    public let supportsColoredOutput: Bool
    public var maxLevel: LogLevel = .info

    private let queue = DispatchQueue(label: "LoggerInfo.queue")

    // MARK: Lifecycle

    public init() {
        self.supportsColoredOutput = Self.supportsColoredOutput()
    }

    // MARK: Functions

    public func configure(verbose: Bool) {
        if verbose {
            self.maxLevel = .verbose
        } else {
            self.maxLevel = .info
        }
    }
}

// MARK: - Private

private extension LoggerInfo {

    /// Detects if the terminal supports colored output.
    private static func supportsColoredOutput() -> Bool {
        guard let term = ProcessInfo.processInfo.environment["TERM"] else {
            return false
        }
        return term.lowercased().contains("color") && isatty(STDOUT_FILENO) != 0
    }
}

/// Prints normal logs if running in Xcode, and colored logs if supported in a shell.
public func log(_ message: String, level: LoggerInfo.LogLevel = .info) {
    guard level >= LoggerInfo.shared.maxLevel else { return }

    if LoggerInfo.shared.supportsColoredOutput {
        if let logLevel = level.coloredLogLevel() {
            print(logLevel + " " + message) // swiftlint:disable:this print_usage
        } else {
            print(message) // swiftlint:disable:this print_usage
        }
    } else {
        if level.rawValue.isEmpty == false {
            print("\(level.rawValue.uppercased()) \(message)") // swiftlint:disable:this print_usage
        } else {
            print(message) // swiftlint:disable:this print_usage
        }
    }
}

public func abort(_ error: some Error) -> Never {
    func extractMessage(from error: Error) -> String {
        if let description = (error as? LocalizedError)?.errorDescription {
            return description
        } else {
            return error.localizedDescription
        }
    }
    let message = extractMessage(from: error)
    log(message, level: .error)

    try? FileHandle.standardOutput.synchronize()
    exit(EXIT_FAILURE)
}
