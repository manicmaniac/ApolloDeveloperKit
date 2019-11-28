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
public enum HTTPServerError: CustomNSError {
    /// Thrown when the server failed to create a new socket.
    case socketCreationFailed
    /// Thrown when the server failed to set option to a newly created socket.
    case socketSetOptionFailed
    /// Thrown when the server failed to set address to a newly created socket.
    case socketSetAddressFailed
    /// Thrown when timeout occurred while setting address to a newly created socket.
    case socketSetAddressTimeout
    /// Thrown when the server failed to start listening a given port.
    case socketListenFailed
    /// Thrown when multiple errors occurred while creating a new socket.
    case multipleSocketErrorOccurred([UInt16: Error])

    public static let errorDomain = "HTTPServerErrorDomain"

    public var errorCode: Int {
        switch self {
        case .socketCreationFailed:
            return 100
        case .socketSetOptionFailed:
            return 101
        case .socketSetAddressFailed:
            return 102
        case .socketSetAddressTimeout:
            return 103
        case .socketListenFailed:
            return 104
        case .multipleSocketErrorOccurred:
            return 199
        }
    }

    /**
     * The error's localized description.
     *
     * - Warning: Currently localized only in English.
     */
    public var localizedDescription: String {
        switch self {
        case .socketCreationFailed:
            return "Failed to create the socket."
        case .socketSetOptionFailed:
            return "Failed to set option to the socket."
        case .socketSetAddressFailed:
            return "Failed to set address to the socket."
        case .socketSetAddressTimeout:
            return "Failed to set address to the socket due to timeout."
        case .socketListenFailed:
            return "Failed to listen to the socket."
        case .multipleSocketErrorOccurred:
            return "Multiple error occurred while creating socket(s)."
        }
    }
}
