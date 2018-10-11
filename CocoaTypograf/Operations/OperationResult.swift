//
//  OperationResult.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 11/10/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

public enum OperationResult<ValueType, ErrorType> {
    case success(ValueType)
    case failure(ErrorType)
    case cancelled
}
