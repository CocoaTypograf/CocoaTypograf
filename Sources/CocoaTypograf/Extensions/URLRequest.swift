//
//  URLRequest.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 12.08.2020.
//  Copyright © 2020 dreadct. All rights reserved.
//

import Foundation

internal extension URLRequest {

    /// Initializes a new `URLRequest` based on a text
    /// required to be processed by the typograf.
    ///
    /// - Parameters:
    ///   - text: A text to process.
    ///   - parameters: Parameters for processing the specified text.
    init(text: String,
         parameters: ProcessTextParameters) {
        self.init(url: RequestConstants.url)

        setValue(RequestConstants.contentType,
                 forHTTPHeaderField: Headers.contentType)
        httpMethod = RequestConstants.httpMethod
        httpBody = parameters.requestBody(text: text).data(using: .utf8)
    }

}

// MARK: - Constants

fileprivate extension URLRequest {

    enum Headers {
        static let contentType = "Content-Type"
    }

    enum RequestConstants {
        static let contentType = "application/soap+xml; charset=utf-8"
        static let httpMethod = "POST"
        static let url = URL(string: "http://typograf.artlebedev.ru/webservices/typograf.asmx")!
    }

}
