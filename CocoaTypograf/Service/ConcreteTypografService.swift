//
//  ConcreteTypografService.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

public final class ConcreteTypografService: TypografService {

    // MARK: - Properties

    private var session: URLSession

    // MARK: - Initializers

    public convenience init() {
        self.init(session: URLSession(configuration: .default))
    }

    public init(session: URLSession) {
        self.session = session
    }

    deinit {
        session.invalidateAndCancel()
    }

    // MARK: - Public methods

    @discardableResult
    public func processText(parameters: ProcessTextParameters,
                            completion: @escaping (OperationResult<String, TypografServiceError>) -> Void) -> OperationToken {
        var request = URLRequest(url: Constants.Request.url)
        request.setValue(Constants.Request.contentType,
                         forHTTPHeaderField: Constants.HeaderNames.contentType)
        request.httpMethod = Constants.Request.httpMethod

        let bodyString = parameters.requestBodyText
        request.httpBody = bodyString.data(using: .utf8)

        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            // check if there was an error
            if let error = error {
                let code = (error as NSError).code
                if code == NSURLErrorCancelled {
                    completion(.cancelled)
                } else {
                    completion(.failure(.responseError(error)))
                }
                return
            }

            // ensure request is present and has a proper type
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.serviceUnavailable))
                return
            }

            // check the status code
            guard 200 ... 299 ~= httpResponse.statusCode else {
                completion(.failure(.serviceUnavailable))
                return
            }

            // get the data
            guard let data = data else {
                completion(.failure(.serviceUnavailable))
                return
            }

            // try to get actual response encoding
            var encoding: String.Encoding = .utf8
            if let encodingName = httpResponse.textEncodingName {
                let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
                if cfEncoding != kCFStringEncodingInvalidId {
                    let nsEncoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
                    encoding = String.Encoding(rawValue: nsEncoding)
                }
            }

            // validate content-type

            guard let responseText = self?.parseTextFromResponse(data: data, encoding: encoding) else {
                completion(.failure(.invalidResponseData))
                return
            }

            completion(.success(responseText))
        }

        task.resume()

        return OperationToken {
            task.cancel()
        }
    }

    // MARK: - Private methods

    private func parseTextFromResponse(data: Data, encoding: String.Encoding) -> String? {
        guard let responseString = String(data: data, encoding: encoding) else {
            return nil
        }

        guard let regex = try? NSRegularExpression(pattern: Constants.Response.regexPattern, options: []) else {
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

// MARK: - Constants

extension ConcreteTypografService {

    fileprivate enum Constants {

        fileprivate enum HeaderNames {
            static let contentType = "Content-Type"
        }

        fileprivate enum Request {
            static let contentType = "application/soap+xml; charset=utf-8"
            static let httpMethod = "POST"
            static let url = URL(string: "http://typograf.artlebedev.ru/webservices/typograf.asmx")!
        }

        fileprivate enum Response {
            static let regexPattern = NSLocalizedString("soap.response.processText.regex.text",
                                                        tableName: "SOAP",
                                                        bundle: Bundle.current,
                                                        comment: "")
        }

    }

}
