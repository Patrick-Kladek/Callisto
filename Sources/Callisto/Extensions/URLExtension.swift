//
//  URLExtension.swift
//  analytics-generator
//
//  Created by Patrick Kladek on 10.12.24.
//

import ArgumentParser
import Foundation

extension URL: @retroactive ExpressibleByArgument {

    public init?(argument: String) {
        if argument.hasPrefix("~") {
            // Expand `~` manually
            let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
            let path = argument.replacingOccurrences(of: "~/", with: "")
            self.init(filePath: path, relativeTo: homeDirectory)
        } else {
            // Use the path as is
            self.init(fileURLWithPath: argument)
        }
    }
}
