//
//  GithubRepository.swift
//  Callisto
//
//  Created by Patrick Kladek on 02.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation

public struct GithubRepository {

    public let organisation: String
    public let repository: String

    public init(organisation: String, repository: String) {
        self.organisation = organisation
        self.repository = repository
    }
}
