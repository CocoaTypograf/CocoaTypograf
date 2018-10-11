//
//  CocoaTypografTests.swift
//  CocoaTypografTests
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import XCTest

class CocoaTypografTests: XCTestCase {

    // MARK: - Properties

    var service: TypografService!
    let timeout: TimeInterval = 30.0

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()

        service = ConcreteTypografService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Test methods

    func testCancellation() {
        let token = process(text: "") { responseText in
            XCTAssertNil(responseText, "Operation wasn't cancelled")
        }
        token.cancel()

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testNbspProcessing() {
        process(text: Constants.nbspSourceString) { responseText in
            XCTAssertEqual(Constants.nbspExpectedString, responseText)
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    func testQuotesProcessing() {
        process(text: Constants.quotesSourceString) { responseText in
            XCTAssertEqual(Constants.quotesExpectedString, responseText)
        }

        waitForExpectations(timeout: timeout, handler: nil)
    }

    // MARK: - Private methods

    @discardableResult
    private func process(text: String,
                         completion: @escaping (String?) -> Void) -> OperationToken {
        let responseExpectation = expectation(description: "Wait for response for text \"\(text)\"")

        let params = ProcessTextParameters(text: text)
        return service.processText(parameters: params) { result in
            switch result {
            case .cancelled:
                completion(nil)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            case .success(let text):
                completion(text)
            }
            responseExpectation.fulfill()
        }
    }

}

// MARK: - Constants

extension CocoaTypografTests {

    fileprivate enum Constants {
        static let nbspSourceString = NSLocalizedString("test.nbsp.source", tableName: "Test", bundle: Bundle.current, comment: "")
        static let nbspExpectedString = NSLocalizedString("test.nbsp.expected", tableName: "Test", bundle: Bundle.current, comment: "")
        static let quotesSourceString = NSLocalizedString("test.quotes.source", tableName: "Test", bundle: Bundle.current, comment: "")
        static let quotesExpectedString = NSLocalizedString("test.quotes.expected", tableName: "Test", bundle: Bundle.current, comment: "")
    }

}
