//
//  DictionaryConvertable.swift
//  clangParser
//
//  Created by Patrick Kladek on 27.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation

protocol DictionaryConvertable {
    func dictionaryRepresentation() -> [String: Any]
}
