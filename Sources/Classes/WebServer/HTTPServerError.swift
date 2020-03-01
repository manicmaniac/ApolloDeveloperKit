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

    public static let errorDomain = "HTTPServerErrorDomain"

    public var errorCode: Int {
        switch self {
        case .multipleSocketErrorOccurred:
            return 199
        }
    }

    public var errorDescription: String? {
        switch self {
        case .multipleSocketErrorOccurred:
            return "Multiple error occurred while creating socket(s)."
        }
    }
}
