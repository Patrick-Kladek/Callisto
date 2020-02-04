//
//  Collection+Sugar.swift
//  Callisto
//
//  Created by Patrick Kladek on 14.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


extension Collection {

    var hasElements: Bool {
        return self.isEmpty == false
    }
}


extension Array where Element: Equatable {

    mutating func delete(_ object: Element) {
        guard let index = self.firstIndex(of: object) else { return }

        self.remove(at: index)
    }

    func deleting(_ object: Element) -> Array<Element> {
        var array = self
        array.delete(object)
        return array
    }

    mutating func delete(_ objects: [Element]) {
        for object in objects {
            self.delete(object)
        }
    }

    func deleting(_ objects: [Element]) -> Array<Element> {
        var array = self
        array.delete(objects)
        return array
    }
}
