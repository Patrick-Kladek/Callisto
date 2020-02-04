//
//  Result+Sugar.swift
//  Callisto
//
//  Created by Patrick Kladek on 14.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


extension Result where Success == Void {
    static var success: Result {
        return .success(())
    }
}
