//
//  TypografService.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

/// A protocol describing a typograf service.
public protocol TypografService {

    /// A closure for handling a result of a text processing.
    ///
    /// The result might be a success or a failure.
    /// - Parameter result: A result of a text processing operation.
    typealias CompletionHandler = (_ result: Result<String, TypografServiceError>) -> Void

    // MARK: - Methods

    /// Asynchronously performs a typographic processing of a given text with given parameters.
    ///
    /// After processing is completed the provided completion handler is called with a processing result.
    ///
    /// - Parameter text: A text to process.
    /// - Parameter parameters: Parameters for processing the specified text.
    /// - Parameter completion: A completion handler called after processing the text.
    /// - Returns: An operation token that could be used for cancelling the asynchronous processing.
    @discardableResult
    func process(text: String,
                 parameters: ProcessTextParameters,
                 completion: @escaping CompletionHandler) -> CancellationToken

}
