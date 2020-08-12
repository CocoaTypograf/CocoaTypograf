//
//  URLResponse.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 12.08.2020.
//  Copyright © 2020 dreadct. All rights reserved.
//

import Foundation

internal extension URLResponse {

    /// Returns a body encoding with UTF-8 encoding
    /// used as a fall-back encoding.
    var bodyEncoding: String.Encoding {
        return textEncodingName
            .map { CFStringConvertIANACharSetNameToEncoding($0 as CFString) }
            .map { CFStringConvertEncodingToNSStringEncoding($0) }
            .flatMap { String.Encoding(rawValue: $0) }
            ?? .utf8
    }

    /// Returns a typograf response text.
    ///
    /// - Parameter bodyData: A data rerpesenting
    ///                       a body of the response
    /// - Returns: A `String` representing a typograf processed text
    ///            from the response if available, or `nil` otherwise.
    func typografResponseText(from bodyData: Data) -> String? {
        guard let bodyString = String(data: bodyData, encoding: bodyEncoding) else {
            return nil
        }

        return parseResponseText(from: bodyString)
    }

}

// MARK: - Private methods

fileprivate extension URLResponse {

    func parseResponseText(from bodyString: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: ResponseConstants.regexPattern,
                                                   options: []) else {
            return nil
        }

        let wholeStringRange = NSRange(location: 0, length: bodyString.utf16.count)
        guard let match = regex.firstMatch(in: bodyString,
                                           options: [],
                                           range: wholeStringRange),
              match.numberOfRanges == ResponseConstants.regexNumberOfRanges else {
            return nil
        }

        guard let range = Range(match.range(at: 1), in: bodyString) else {
            return nil
        }

        return String(bodyString[range])
    }

}

// MARK: - Constants

fileprivate extension URLResponse {

    enum ResponseConstants {
        static let regexNumberOfRanges = 2
        static let regexPattern = "<ProcessTextResult.*?>([\\s\\S]*?)\\n?<\\/ProcessTextResult.*?>"
    }

}
