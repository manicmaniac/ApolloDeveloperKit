//
//  HTTPServerError.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 7/13/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

public enum HTTPServerError: CustomNSError {
    case socketCreationFailed
    case socketSetOptionFailed
    case socketSetAddressFailed
    case socketSetAddressTimeout
    case socketListenFailed
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
