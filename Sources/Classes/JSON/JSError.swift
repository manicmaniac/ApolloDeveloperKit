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
struct JSError {
    /**
     * The localized message describing this error.
     */
    let message: String?

    /**
     * The filename where this error occurs.
     */
    let fileName: String?

    /**
     * The line number where this error occurs.
     */
    let lineNumber: Int?

    /**
     * Initializes `JSError` instance.
     *
     * - Parameter error: An error.
     * - Parameter fileName: The file name where the error occurs.
     * - Parameter lineNumber: The Number of line in the file where the error occurs.
     */
    init(_ error: Error, fileName: String = #file, lineNumber: Int = #line) {
        self.message = error.localizedDescription
        self.fileName = fileName
        self.lineNumber = lineNumber
    }
}

    // MARK: - JSONEncodable

extension JSError: JSONEncodable {
    var jsonValue: JSONValue {
        return [
            "message": message.jsonValue,
            "fileName": fileName.jsonValue,
            "lineNumber": lineNumber.jsonValue
        ]
    }
}
