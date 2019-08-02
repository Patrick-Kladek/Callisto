//
//  main.swift
//  clangParser
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation
import Cocoa
import Darwin // we need Darwin for exit() function


func main() {
    let defaults = UserDefaults.standard

    if (CommandLine.arguments.contains("-help") || CommandLine.arguments.contains("-info")) {
        LogMessage("Callisto \(AppInfo.version))")
        exit(0)
    }

    switch defaults.action {
    case .summarize:
        let action = SummariseAction(defaults: defaults)
        action.run()

    case .upload:
        let action = UploadAction(defaults: defaults)
        action.run()

    case .unknown:
        quit()
    }
}

main()

