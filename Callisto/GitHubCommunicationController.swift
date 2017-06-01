//
//  GitHubCommunicationController.swift
//  clangParser
//
//  Created by Patrick Kladek on 21.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

class GitHubCommunicationController {

    public let account: GithubAccount
    public let organisation: String
    public let repository: String

    fileprivate let baseUrl = URL(string: "https://api.github.com")

    init(account: GithubAccount, organisation: String, repository: String) {
        self.account = account
        self.organisation = organisation
        self.repository = repository
    }

    func pullRequest(forBranch branch: String) throws -> [String: Any] {
        let pullRequests = self.allPullRequests()
        return try pullRequests.first { pullRequest -> Bool in
            guard let pullRequestBranch = pullRequest[keyPath: "head.ref"] as? String else { throw GithubError.pullRequestNotAvailible }

            return pullRequestBranch == branch
        } ?? [:]
    }
}

fileprivate extension GitHubCommunicationController {

    func makeUrl(organisation: String, repository: String) -> URL? {
        guard let baseUrl = self.baseUrl else { return nil }

        return baseUrl.appendingPathComponent("repos").appendingPathComponent(organisation).appendingPathComponent(repository)
    }
}

enum StatusCodeError: Error {
    case noResponse
    case noData
}

enum GithubError: Error {
    case pullRequestNotAvailible
    case pullRequestNoURL
}

extension GitHubCommunicationController {

    func allPullRequests() -> [[String: Any]] {
        guard let repositoryUrl = self.makeUrl(organisation: self.organisation, repository: self.repository) else { return [] }
        let pullRequestUrl = repositoryUrl.appendingPathComponent("pulls")

        do {
            let taskResult = try URLSession.shared.synchronousDataTask(with: self.defaultRequest(url: pullRequestUrl))

            if taskResult.response?.statusCode != 200 {
                NSLog("Error by sending Message!")
                NSLog("%@", taskResult.response ?? "<nil>")
                throw StatusCodeError.noResponse
            }

            if let data = taskResult.data {
                return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] ?? []
            } else {
                throw StatusCodeError.noData
            }
        } catch {
            fatalError()
        }

        return []
    }

    func defaultRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("application/vnd.github.loki-preview+json", forHTTPHeaderField: "Accept")

        let loginString = String(format: "%@:%@", self.account.username, self.account.token)
        let loginData = loginString.data(using: String.Encoding.utf8)!
        let base64LoginString = loginData.base64EncodedString()
        request.setValue("Basic \(base64LoginString)", forHTTPHeaderField: "Authorization")

        return request
    }
}
