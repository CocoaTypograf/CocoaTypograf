//
//  Bundle.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

internal extension Bundle {

    /// Returns a current bundle.
    static var current: Bundle {
        @objc final class _BundleAnchor: NSObject {}
        return Bundle(for: _BundleAnchor.self)
    }

}
