//
//  HTTPServerError.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 7/13/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

public enum HTTPServerError: Int, CustomNSError {
    public static let errorDomain = "HTTPServerErrorDomain"

    case socketCreationFailed = 100
    case socketSetOptionFailed = 101
    case socketSetAddressFailed = 102
    case socketSetAddressTimeout = 103
    case socketListenFailed = 104

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
        }
    }
}
