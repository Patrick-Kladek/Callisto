//
//  Branch.swift
//  clangParser
//
//  Created by Patrick Kladek on 26.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

struct Branch {

    public var title: String?
    public var name: String?
    public var url: URL?
    public var number: Int?
}


extension Branch {

    var slackTitle: String? {
        guard let title = self.title else { return nil }

        if let number = self.number {
            return "\(title) #\(number)"
        }
        
        return title
    }
}
