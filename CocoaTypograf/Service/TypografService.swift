//
//  TypografService.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

public protocol TypografService {

    typealias CompletionHandler = (_ result: Result<String, TypografServiceError>) -> Void

    // MARK: - Methods

    @discardableResult
    func processText(parameters: ProcessTextParameters,
                     completion: @escaping (Result<String, TypografServiceError>) -> Void) -> OperationToken

}
