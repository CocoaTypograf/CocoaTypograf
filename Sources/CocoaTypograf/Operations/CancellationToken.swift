//
//  CancellationToken.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 11/10/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

/// Represents a token for cancelling asynchronous operations.
public struct CancellationToken {

    // MARK: - Properties

    /// An associated cancellation closure.
    private let cancellation: () -> Void

    /// Indicates whether the token was already cancelled.
    private(set) var isCancelled: Bool = false {
        didSet {
            if !oldValue && isCancelled {
                cancellation()
            }
        }
    }

    // MARK: - Initializers

    /// Initializes a new cancellation token with a given cancellation closure.
    /// - Parameter cancellation: A cancellation closure to be associeted with the token.
    /// Called once after the token is cancelled.
    public init(cancellation: @escaping () -> Void) {
        self.cancellation = cancellation
    }

    // MARK: - Public methods

    /// Cancels an associated operation by calling
    /// an initially passed cancellation closure.
    public mutating func cancel() {
        isCancelled = true
    }

}
