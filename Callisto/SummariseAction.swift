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

    // MARK: - SummariseAction

    func run() -> Never {
        let url = defaults.fastlaneOutputURL
        let ignoredKeywords = defaults.ignoredKeywords

        guard let extractController = ExtractBuildInformationController(contentsOfFile: url, ignoredKeywords: ignoredKeywords) else { exit(ExitCodes.internalError.rawValue) }

        switch extractController.run() {
        case .success:
            let tempURL = URL.tempURL(extractController.buildInfo.platform)
            let result = extractController.save(to: tempURL)
            switch result {
            case .success:
                print("Succesfully saved summarized output at: \(tempURL)")
                quit(.success)
            case .failure(let error):
                LogError("Saving summary failed: \(error)")
                quit(.savingFailed)
            }

        case .failure:
            quit(.parsingFailed)
        }
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
