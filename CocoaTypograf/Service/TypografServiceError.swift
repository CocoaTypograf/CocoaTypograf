//
//  TypografServiceError.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 11/10/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

public enum TypografServiceError: Error {
    case responseError(Error)
    case invalidResponseData
    case serviceUnavailable
}
