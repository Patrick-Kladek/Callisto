//
//  URLSession+synchronousTask.swift
//  clangParser
//
//  Created by Patrick Kladek on 21.04.17.
//  Copyright © 2017 Patrick Kladek. All rights reserved.
//

import Foundation

extension URLSession {

    func synchronousDataTask(with request: URLRequest) throws -> (data: Data?, response: HTTPURLResponse?) {
        let semaphore = DispatchSemaphore(value: 0)

        var responseData: Data?
        var theResponse: URLResponse?
        var theError: Error?

        self.dataTask(with: request) { data, response, error in
            responseData = data
            theResponse = response
            theError = error

            semaphore.signal()

            }.resume()

        _ = semaphore.wait(timeout: .distantFuture)

        if let error = theError {
            throw error
        }

        return (data: responseData, response: theResponse as! HTTPURLResponse?) // swiftlint:disable:this force_cast
    }
}
