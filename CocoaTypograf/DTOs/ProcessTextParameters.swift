//
//  ProcessTextParameters.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

struct ProcessTextParameters {

    // MARK: - Properties

    let entityType: EntityType
    let maxNonBreakingSpaces: UInt
    let text: String
    let useBreakLineTags: Bool
    let useParagraphTags: Bool

    // MARK: - Initializers

    init(text: String,
         entityType: EntityType = .none,
         maxNonBreakingSpaces: UInt = 0,
         useBreakLineTags: Bool = false,
         useParagraphTags: Bool = false) {
        self.entityType = entityType
        self.text = text
        self.maxNonBreakingSpaces = maxNonBreakingSpaces
        self.useBreakLineTags = useBreakLineTags
        self.useParagraphTags = useParagraphTags
    }

}

// MARK: - Constants

extension ProcessTextParameters {

    fileprivate enum Constants {
        static let bodyFormatString = NSLocalizedString("soap.request.processText.format",
                                                        tableName: "SOAP",
                                                        bundle: Bundle.current,
                                                        comment: "")
    }

}

// MARK: - Body text presentation

extension ProcessTextParameters {

    var requestBodyText: String {
        return String(format: Constants.bodyFormatString,
                      text,
                      entityType.rawValue,
                      maxNonBreakingSpaces,
                      useBreakLineTags ? "true" : "false",
                      useParagraphTags ? "true" : "false")
    }

}
