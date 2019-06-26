//
//  CancellationToken.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 11/10/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

public struct CancellationToken {

    // MARK: - Properties

    private let cancellation: () -> Void

    private(set) var isCancelled: Bool = false {
        didSet {
            if !oldValue && isCancelled {
                cancellation()
            }
        }
    }

    // MARK: - Initializers

    init(cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }

    // MARK: - Public methods

    public mutating func cancel() {
        isCancelled = true
    }

}
