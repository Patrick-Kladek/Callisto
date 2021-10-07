//
//  GitHubCommunicationController.swift
//  clangParser
//
//  Created by Patrick Kladek on 21.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

class GitHubCommunicationController {

    public let access: GithubAccess
    public let repository: GithubRepository

    fileprivate let baseUrl = URL(string: "https://api.github.com")

    init(access: GithubAccess, repository: GithubRepository) {
        self.access = access
        self.repository = repository
    }

    func pullRequest(forBranch branch: String) throws -> [String: Any] {
        let pullRequests = self.allPullRequests()
        return try pullRequests.first { pullRequest -> Bool in
            guard let pullRequestBranch = pullRequest[keyPath: "head.ref"] as? String else { throw GithubError.pullRequestNotAvailible }

            return pullRequestBranch == branch
        } ?? [:]
    }

    func branch(named name: String) -> Result<Branch, Error> {
        do {
            let dict: [String: Any]
            try dict = self.pullRequest(forBranch: name)
            guard let branchPath = dict["html_url"] as? String, let title = dict["title"] as? String else { throw GithubError.pullRequestNoURL }

            let prNumber = dict["number"] as? Int
            return .success(Branch(title: title, name: name, url: URL(string: branchPath), number: prNumber))
        } catch {
            LogError("Something happend when collecting information about Pull Requests")
            return .failure(error)
        }
    }

    func postComment(on branch: Branch, comment: Comment) -> Result<Void, Error> {
        guard let url = self.makeCommentURL(for: branch) else { return .failure(StatusCodeError.noPullRequestURL) }

        do {
            var request = self.defaultRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try JSONEncoder().encode(comment)
            let taskResult = try URLSession.shared.synchronousDataTask(with: request)

            if taskResult.response?.statusCode != 201 {
                LogError(taskResult.response.debugDescription)
                throw StatusCodeError.noResponse
            }

            if taskResult.data == nil {
                throw StatusCodeError.noData
            }

            return .success
        } catch {
            return .failure(error)
        }
    }

    func fetchPreviousComments(on branch: Branch) -> Result<[Comment], Error> {
        guard let url = self.makeCommentURL(for: branch) else { return .failure(StatusCodeError.noPullRequestURL) }

        do {
            let request = self.defaultRequest(url: url)
            let taskResult = try URLSession.shared.synchronousDataTask(with: request)

            if taskResult.response?.statusCode != 200 {
                LogError(taskResult.response.debugDescription)
                throw StatusCodeError.noResponse
            }

            guard let data = taskResult.data else { throw StatusCodeError.noData }

            let comments = try JSONDecoder().decode([Comment].self, from: data)
            return .success(comments)
        } catch {
            return .failure(error)
        }
    }

    func deleteComment(comment: Comment) -> Result<Void, Error> {
        guard let id = comment.id else { return .failure(StatusCodeError.noPullRequestURL )}
        guard let url = self.makeDeleteCommentURL(for: id) else { return .failure(StatusCodeError.noPullRequestURL) }

        do {
            var request = self.defaultRequest(url: url)
            request.httpMethod = "DELETE"
            let taskResult = try URLSession.shared.synchronousDataTask(with: request)

            if taskResult.response?.statusCode != 204 {
                LogError(taskResult.response.debugDescription)
                throw StatusCodeError.noResponse
            }

            return .success
        } catch {
            return .failure(error)
        }
    }
}

fileprivate extension GitHubCommunicationController {

    func makeUrl(repository: GithubRepository) -> URL? {
        guard let baseUrl = self.baseUrl else { return nil }

        return baseUrl.appendingPathComponent("repos").appendingPathComponent(repository.organisation).appendingPathComponent(repository.repository)
    }

    func makeCommentURL(for branch: Branch) -> URL? {
        guard let prNumber = branch.number else { return nil }

        var url = self.baseUrl
        url?.appendPathComponent("repos")
        url?.appendPathComponent(self.repository.organisation.lowercased())
        url?.appendPathComponent(self.repository.repository.lowercased())
        url?.appendPathComponent("issues")
        url?.appendPathComponent("\(prNumber)")
        url?.appendPathComponent("comments")

        return url
    }

    func makeDeleteCommentURL(for issue: Int) -> URL? {
        var url = self.baseUrl
        url?.appendPathComponent("repos")
        url?.appendPathComponent(self.repository.organisation.lowercased())
        url?.appendPathComponent(self.repository.repository.lowercased())
        url?.appendPathComponent("issues")
        url?.appendPathComponent("comments")
        url?.appendPathComponent("\(issue)")
        return url
    }
}

enum StatusCodeError: Error {
    case noResponse
    case noData
    case noPullRequestURL

    var localizedDescription: String {
        switch self {
        case .noData:
            return "Could not parse data from github"
        case .noResponse:
            return "Github did not respond to request"
        case .noPullRequestURL:
            return "Could not find Github PullRequest URL"
        }
    }
}

enum GithubError: Error {
    case pullRequestNotAvailible
    case pullRequestNoURL
}

extension GitHubCommunicationController {

    func allPullRequests() -> [[String: Any]] {
        guard let repositoryUrl = self.makeUrl(repository: self.repository) else { return [] }
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
            LogError(error.localizedDescription)
            return []
        }
    }

    func defaultRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue("application/vnd.github.antiope-preview+json", forHTTPHeaderField: "Accept")
        request.setValue("token \(self.access.token)", forHTTPHeaderField: "Authorization")

        return request
    }
}

private extension Branch {

    var withAPIHost: Branch? {
        guard let url = url else { return nil }

        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        urlComponents?.host = "api.github.com"

        return Branch(title: self.title, name: self.name, url: urlComponents?.url, number: nil)
    }
}
