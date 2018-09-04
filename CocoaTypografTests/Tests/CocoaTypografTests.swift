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

    var service: TypografServiceType!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()

        service = TypografService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Test methods

    func testNbspProcessing() {
        process(text: Constants.nbspSourceString) { responseText in
            XCTAssertEqual(Constants.nbspExpectedString, responseText)
        }
    }

    func testQuotesProcessing() {
        process(text: Constants.quotesSourceString) { responseText in
            XCTAssertEqual(Constants.quotesExpectedString, responseText)
        }
    }

    // MARK: - Private methods

    private func process(text: String, timeout: TimeInterval = 30.0, completion: (String) -> Void) {
        let responseExpectation = expectation(description: "Wait for response for text \"\(text)\"")

        var responseText: String!
        let params = ProcessTextParameters(text: text)
        service.processText(parameters: params) { (text, error) in
            XCTAssertNil(error)
            responseExpectation.fulfill()
            responseText = text
        }

        waitForExpectations(timeout: timeout, handler: nil)
        XCTAssertNotNil(responseText)

        completion(responseText)
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
