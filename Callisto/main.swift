//
//  main.swift
//  clangParser
//
//  Created by Patrick Kladek on 19.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation
import Cocoa


func main() {
    let defaults = UserDefaults.standard

    switch defaults.action {
    case .help:
        LogMessage("Callisto \(AppInfo.version))")
        exit(0)

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

