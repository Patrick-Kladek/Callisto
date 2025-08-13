//
//  GitHubCommunicationController.swift
//  clangParser
//
//  Created by Patrick Kladek on 21.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation
import Common

public class GitHubCommunicationController {

    public let access: GithubAccess
    public let repository: GithubRepository

    fileprivate let baseUrl = URL(string: "https://api.github.com")

    public init(access: GithubAccess, repository: GithubRepository) {
        self.access = access
        self.repository = repository
    }

    public func pullRequest(forBranch branch: String) async throws -> [String: Any] {
        let pullRequests = try await self.allPullRequests()
        return try pullRequests.first { pullRequest -> Bool in
            guard let pullRequestBranch = pullRequest[keyPath: "head.ref"] as? String else { throw GithubError.pullRequestNotAvailible }

            return pullRequestBranch == branch
        } ?? [:]
    }

    public func branch(named name: String) async -> Result<Branch, Error> {
        do {
            let dict: [String: Any]
            try dict = await self.pullRequest(forBranch: name)
            guard let branchPath = dict["html_url"] as? String, let title = dict["title"] as? String else { throw GithubError.pullRequestNoURL }

            let prNumber = dict["number"] as? Int
            return .success(Branch(title: title, name: name, url: URL(string: branchPath), number: prNumber))
        } catch {
            log("Something happend when collecting information about Pull Requests", level: .error)
            return .failure(error)
        }
    }

    public func postComment(on branch: Branch, comment: Comment) async throws -> Result<Void, Error> {
        guard let url = self.makeCommentURL(for: branch) else { return .failure(StatusCodeError.noPullRequestURL) }

        do {
            var request = self.defaultRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try JSONEncoder().encode(comment)

            let (_, response) = try await URLSession.shared.data(for: request)

            if (response as! HTTPURLResponse).statusCode != 201 {
                log(response.debugDescription, level: .error)
                throw StatusCodeError.noResponse
            }

            return .success
        } catch {
            return .failure(error)
        }
    }

    public func fetchPreviousComments(on branch: Branch) async throws -> Result<[Comment], Error> {
        guard let url = self.makeCommentURL(for: branch) else { return .failure(StatusCodeError.noPullRequestURL) }

        do {
            let request = self.defaultRequest(url: url)
            let (data, response) = try await URLSession.shared.data(for: request)

            if (response as! HTTPURLResponse).statusCode != 200 {
                log(response.debugDescription, level: .error)
                throw StatusCodeError.noResponse
            }

            let comments = try JSONDecoder().decode([Comment].self, from: data)
            return .success(comments)
        } catch {
            return .failure(error)
        }
    }

    public func deleteComment(comment: Comment) async throws -> Result<Void, Error> {
        guard let id = comment.id else { return .failure(StatusCodeError.noPullRequestURL )}
        guard let url = self.makeDeleteCommentURL(for: id) else { return .failure(StatusCodeError.noPullRequestURL) }

        do {
            var request = self.defaultRequest(url: url)
            request.httpMethod = "DELETE"
            let (_, response) = try await URLSession.shared.data(for: request)

            if (response as! HTTPURLResponse).statusCode != 204 {
                log(response.debugDescription, level: .error)
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

    func allPullRequests() async throws -> [[String: Any]] {
        guard let repositoryUrl = self.makeUrl(repository: self.repository) else { return [] }

        let pullRequestUrl = repositoryUrl.appendingPathComponent("pulls")

        let request = self.defaultRequest(url: pullRequestUrl)
        let (data, response) = try await URLSession.shared.data(for: request)

        if (response as! HTTPURLResponse).statusCode != 200 {
            log("Error by sending Message!", level: .error)
            log("\(response)", level: .error)
            throw StatusCodeError.noResponse
        }

        return try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [[String: Any]] ?? []
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
