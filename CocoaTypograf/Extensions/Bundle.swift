//
//  Bundle.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

internal extension Bundle {

    @objc fileprivate final class _BundleAnchor: NSObject {
    }

    /// Returns a current bundle.
    static var current: Bundle {
        return Bundle(for: _BundleAnchor.self)
    }

}
