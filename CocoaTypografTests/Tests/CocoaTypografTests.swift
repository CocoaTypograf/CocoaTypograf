//
//  CocoaTypografTests.swift
//  CocoaTypografTests
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import XCTest

final class CocoaTypografTests: XCTestCase {

    // MARK: - Properties

    var service: TypografService!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()

        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = Constants.timeout
        sessionConfig.timeoutIntervalForResource = Constants.timeout
        let session = URLSession(configuration: sessionConfig)
        service = ConcreteTypografService(session: session)
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

}

// MARK: - Test methods

extension CocoaTypografTests {

    func testCancellation() {
        let completion: (String) -> Void = { _ in
            XCTFail("Operation wasn't cancelled")
        }
        var token = process(text: "", completion: completion)
        token.cancel()

        let dispatchExpectation = expectation(description: "A dispatch expectation")
        DispatchQueue.main.asyncAfter(deadline: .now()
            + Constants.timeout
            + Constants.postTimeoutExpectationFulfillingDelay) {
                dispatchExpectation.fulfill()
        }

        waitForExpectations(timeout: Constants.timeout + Constants.postTimeoutCancellationAwaitingDelay,
                            handler: nil)
    }

    func testNbspProcessing() {
        let responseExpectation = expectation(description: "Wait for response for text")
        process(text: Constants.nbspSourceString) { responseText in
            responseExpectation.fulfill()
            XCTAssertEqual(Constants.nbspExpectedString, responseText)
        }

        waitForExpectations(timeout: Constants.timeout, handler: nil)
    }

    func testQuotesProcessing() {
        let responseExpectation = expectation(description: "Wait for response for text")
        process(text: Constants.quotesSourceString) { responseText in
            responseExpectation.fulfill()
            XCTAssertEqual(Constants.quotesExpectedString, responseText)
        }

        waitForExpectations(timeout: Constants.timeout, handler: nil)
    }

}

// MARK: - Private methods

extension CocoaTypografTests {

    @discardableResult
    private func process(text: String,
                         completion: @escaping (String) -> Void) -> OperationToken {
        return service.process(text: text, parameters: .init()) { result in
            switch result {
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success(let text):
                completion(text)
            }
        }
    }

}

// MARK: - Constants

extension CocoaTypografTests {

    fileprivate enum Constants {

        static let nbspSourceString = NSLocalizedString("test.nbsp.source",
                                                        tableName: "Test",
                                                        bundle: Bundle.current,
                                                        comment: "")
        static let nbspExpectedString = NSLocalizedString("test.nbsp.expected",
                                                          tableName: "Test",
                                                          bundle: Bundle.current,
                                                          comment: "")
        static let quotesSourceString = NSLocalizedString("test.quotes.source",
                                                          tableName: "Test",
                                                          bundle: Bundle.current,
                                                          comment: "")
        static let quotesExpectedString = NSLocalizedString("test.quotes.expected",
                                                            tableName: "Test",
                                                            bundle: Bundle.current,
                                                            comment: "")

        static let postTimeoutCancellationAwaitingDelay: TimeInterval = 0.25
        static let postTimeoutExpectationFulfillingDelay: TimeInterval = 0.125
        static let timeout: TimeInterval = 5.0

    }

}
