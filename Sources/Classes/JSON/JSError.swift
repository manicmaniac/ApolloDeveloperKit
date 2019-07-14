//
//  JSError.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/17/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

/**
 * `JSError` bridges Swift error and JavaScript error.
 */
public struct JSError: JSONEncodable {
    /**
     * The localized message describing this error.
     */
    let message: String?

    /**
     * The filename where this error occurs.
     *
     * This property is always `nil`.
     */
    let fileName: String? = nil

    /**
     * The line number where this error occurs.
     *
     * This property is always `nil`.
     */
    let lineNumber: Int? = nil

    /**
     * Initializes `JSError` instance.
     *
     * - Parameter error: An error.
     */
    init(error: Error) {
        self.message = error.localizedDescription
    }

    // MARK: - JSONEncodable

    public var jsonValue: JSONValue {
        return [
            "message": message.jsonValue,
            "fileName": fileName.jsonValue,
            "lineNumber": lineNumber.jsonValue
        ]
    }
}
