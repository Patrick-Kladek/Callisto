//
//  SummariseAction.swift
//  Callisto
//
//  Created by Patrick Kladek on 02.08.19.
//  Copyright © 2019 IdeasOnCanvas. All rights reserved.
//

import Foundation


/// Handles all steps from parsing the fastlane output to saving it in a temporary location
final class SummariseAction: NSObject {

    private let defaults: UserDefaults

    // MARK: - Properties

    // MARK: - Lifecycle
	
    init(defaults: UserDefaults) {
        self.defaults = defaults
	}

    // MARK: - NSObject

    // MARK: - SummariseAction

    func run() {
        
    }
}

// MARK: - Private

private extension SummariseAction {

    
}

// MARK: - Strings

private extension SummariseAction {

    enum Strings {
    	
    }
}
