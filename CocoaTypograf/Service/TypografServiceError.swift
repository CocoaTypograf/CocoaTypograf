//
//  TypografServiceError.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 11/10/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

/// A typograf service error.
public enum TypografServiceError: Error {

    /// A typograf service response data is invalid.
    case invalidResponseData

    /// A response error.
    case responseError(Error)

    /// A typograf service is unavailable for some reason.
    case serviceUnavailable

}

// MARK: - CustomNSError

extension TypografServiceError: CustomNSError {

    public var errorUserInfo: [String: Any] {
        var result: [String: Any] = [:]
        if let underlyingError = underlyingError {
            result[NSUnderlyingErrorKey] = underlyingError
        }
        return result
    }

}

// MARK: - Private methods and properties

fileprivate extension TypografServiceError {

    var underlyingError: Error? {
        switch self {
        case .responseError(let error):
            return error
        default:
            return nil
        }
    }

}
