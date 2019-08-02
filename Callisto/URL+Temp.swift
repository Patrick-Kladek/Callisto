//
//  URL+Temp.swift
//  Callisto
//
//  Created by Patrick Kladek on 02.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


public extension URL {

    static func tempURL(_ name: String) -> URL {
        let folder = URL(fileURLWithPath:NSTemporaryDirectory())
            .appendingPathComponent("Callisto")

        do {
            try FileManager().createDirectory(at: folder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            LogError("Could not create temporary file: \(name)")
        }

        return folder
            .appendingPathComponent(name)
            .appendingPathExtension("buildReport")
    }
}
