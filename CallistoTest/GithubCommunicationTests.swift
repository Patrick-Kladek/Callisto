//
//  GithubCommunicationTest.swift
//  CallistoTest
//
//  Created by Patrick Kladek on 12.01.18.
//  Copyright © 2018 IdeasOnCanvas. All rights reserved.
//

import XCTest


class GithubCommunicationTests: XCTestCase {

    func testGithubCommunication() {
        let communicationController = self.communicationController()

        let allPRs = communicationController.allPullRequests()
        XCTAssertFalse(allPRs.isEmpty)

        let settings = self.settingsDictionary()
        let branch = settings["branch"]!
        guard let pullRequest = try? communicationController.pullRequest(forBranch: branch) else { XCTFail(); fatalError() }

        XCTAssertFalse(pullRequest.isEmpty)
    }
}


private extension GithubCommunicationTests {

    func settingsDictionary() -> [String: String] {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "githubSettings", withExtension: "plist") else { XCTFail(); fatalError() }

        return NSDictionary(contentsOf: url) as? [String: String] ?? [:]
    }

    func communicationController() -> GitHubCommunicationController {
        let settings = self.settingsDictionary()

        let username = settings["username"]!
        let token = settings["token"]!
        let organisation = settings["organisation"]!
        let repository = settings["repository"]!


        let account = GithubAccess(token: token)
        return GitHubCommunicationController(access: account, repository: GithubRepository(organisation: organisation, repository: repository))
    }
}
