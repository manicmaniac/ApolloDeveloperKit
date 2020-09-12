//
//  HTTPServerError.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 7/13/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

/**
 * `HTTPServerError` represents an error derives from an underlying HTTP server.
 */
public enum HTTPServerError: CustomNSError, LocalizedError {
    /// Thrown when multiple errors occurred while creating a new socket.
    case multipleSocketErrorOccurred([UInt16: Error])
    case unsupportedBodyEncoding(String)

    public static let errorDomain = "HTTPServerErrorDomain"

    public var errorCode: Int {
        switch self {
        case .multipleSocketErrorOccurred:
            return 199
        case .unsupportedBodyEncoding:
            return 200
        }
    }

    public var errorDescription: String? {
        switch self {
        case .multipleSocketErrorOccurred:
            return "Multiple error occurred while creating socket(s)."
        case .unsupportedBodyEncoding(let encoding):
            return "Failed to parse the given HTTP body encoded in \(encoding)."
        }
    }
}
