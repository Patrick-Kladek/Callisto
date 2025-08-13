//
//  SlackCommunicationController.swift
//  clangParser
//
//  Created by Patrick Kladek on 21.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

public final class SlackCommunicationController: NSObject {

    public let url: URL

    public init(url: URL) {
        self.url = url
        super.init()
    }

    public func post(data: Data) async throws {
        var urlRequest = URLRequest(url: self.url)

        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: urlRequest)

        if (response as! HTTPURLResponse).statusCode != 200 {
            NSLog("Error by sending Message!")
            NSLog("%@", response)
        }
    }
}

extension SlackCommunicationController: URLSessionDelegate {

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        print(error?.localizedDescription ?? "error")
    }
}
