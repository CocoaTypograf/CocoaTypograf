//
//  HTTPURLResponse.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 12.08.2020.
//  Copyright © 2020 dreadct. All rights reserved.
//

import Foundation

internal extension HTTPURLResponse {

    /// Checks whether the response status code
    /// is in range of 200 to 299 inclusively.
    var isStatusCodeSuccessful: Bool {
        return 200 ... 299 ~= statusCode
    }

}
