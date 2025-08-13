//
//  SummaryFile.swift
//  Callisto
//
//  Created by Patrick Kladek on 23.11.21.
//  Copyright © 2021 IdeasOnCanvas. All rights reserved.
//

import Foundation

enum SummaryFile: Codable {
    case dependencies(DependencyInformation)
    case build(BuildInformation)
}

extension SummaryFile {

    static func read(url: URL) -> Result<SummaryFile, Error> {
        let data: Data
        let decoder = JSONDecoder()
        let info: SummaryFile

        do {
            data = try Data(contentsOf: url, options: .uncached)
            info = try decoder.decode(SummaryFile.self, from: data)
        } catch {
            return .failure(error)
        }

        return .success(info)
    }
}
