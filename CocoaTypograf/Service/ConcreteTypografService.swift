//
//  ConcreteTypografService.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

public final class ConcreteTypografService {

    // MARK: - Properties

    private let session: URLSession

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

}

// MARK: - TypografService

extension ConcreteTypografService: TypografService {

    @discardableResult
    public func process(text: String,
                        parameters: ProcessTextParameters,
                        completion: @escaping CompletionHandler) -> CancellationToken {
        let request = URLRequest(text: text, parameters: parameters)

        let task = session.dataTask(with: request) { data, response, error in
            // check if there was an error
            if let error = error {
                let code = (error as NSError).code
                if code != NSURLErrorCancelled {
                    completion(.failure(.responseError(error)))
                }
                return
            }

            // ensure request is present and has a proper type
            // and check the status code
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.isStatusCodeSuccessful else {
                completion(.failure(.serviceUnavailable))
                return
            }

            // attempt to get the response text
            guard let responseText = data.flatMap({ httpResponse.typografResponseText(from: $0) }) else {
                completion(.failure(.invalidResponseData))
                return
            }

            completion(.success(responseText))
        }

        task.resume()

        return CancellationToken {
            task.cancel()
        }
    }

}
