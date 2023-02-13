//
//  SlackCommunicationController.swift
//  clangParser
//
//  Created by Patrick Kladek on 21.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Cocoa

class SlackCommunicationController: NSObject {

    public private(set) var url: URL

    init(url: URL) {
        self.url = url
        super.init()
    }

    func post(data: Data) {
        var urlRequest = URLRequest(url: self.url)

        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = data

        do {
            let (_, response) = try URLSession.shared.synchronousDataTask(with: urlRequest)

            if let statusCode = response?.statusCode, statusCode != 200 {
                NSLog("Error URLRequest Status Code: \(statusCode)")
                NSLog("%@", response ?? "<nil>")
            }
        } catch let error as NSError {
            LogError(String(format: "%@", error))
            fatalError()
        } catch {
            fatalError()
        }
    }
}

extension SlackCommunicationController: URLSessionDelegate {

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        LogError(error?.localizedDescription ?? "error")
    }
}
