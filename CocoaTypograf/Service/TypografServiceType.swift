//
//  TypografServiceType.swift
//  CocoaTypograf
//
//  Created by Vadim Zhilinkov on 04/09/2018.
//  Copyright © 2018 dreadct. All rights reserved.
//

import Foundation

protocol TypografServiceType {

    // MARK: - Types

    typealias CompletionHandler = (String?, Error?) -> Void

    // MARK: - Methods

    func processText(parameters: ProcessTextParameters, completion: @escaping CompletionHandler)

}
