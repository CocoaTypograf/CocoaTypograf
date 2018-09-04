//
//  TypografService.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

final class TypografService: TypografServiceType {

    // MARK: - Constants

    private enum Constants {
        static let httpMethod = "POST"
        static let responseRegexPattern = NSLocalizedString("soap.response.processText.regex.text",
                                                            tableName: "SOAP",
                                                            bundle: Bundle.current,
                                                            comment: "")
        static let url = URL(string: "http://typograf.artlebedev.ru/webservices/typograf.asmx")!
    }

    // MARK: - Errors

    enum ServiceError: Error {
        case serviceUnavailable
        case cantParseResponseData
    }

    // MARK: - Properties

    private var lastTask: URLSessionDataTask? {
        willSet {
            if let lastTask = lastTask, !(newValue?.isEqual(lastTask) ?? false) {
                lastTask.cancel()
            }
        }
    }
    private var session: URLSession

    // MARK: - Initializers

    init() {
        session = URLSession(configuration: .default)
    }

    deinit {
        lastTask = nil
    }

    // MARK: - Public methods

    func processText(parameters: ProcessTextParameters, completion: @escaping CompletionHandler) {
        var request = URLRequest(url: Constants.url)
        request.httpMethod = Constants.httpMethod

        let bodyString = parameters.requestBodyText
        request.httpBody = bodyString.data(using: .utf8)

        lastTask = session.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                200 ... 299 ~= statusCode,
                let data = data else {
                completion(nil, ServiceError.serviceUnavailable)
                return
            }

            guard let responseText = self?.parseTextFromResponse(data: data) else {
                completion(nil, ServiceError.cantParseResponseData)
                return
            }

            completion(responseText, nil)
        }

        lastTask?.resume()
    }

    // MARK: - Private methods

    private func parseTextFromResponse(data: Data) -> String? {
        guard let responseString = String(data: data, encoding: .utf8) else {
            return nil
        }

        guard let regex = try? NSRegularExpression(pattern: Constants.responseRegexPattern, options: []) else {
            return nil
        }

        guard let match = regex.firstMatch(in: responseString, options: [], range: NSMakeRange(0, responseString.utf16.count)),
            match.numberOfRanges == 2 else {
            return nil
        }

        guard let range = Range(match.range(at: 1), in: responseString) else {
            return nil
        }

        return String(responseString[range])
    }

}
