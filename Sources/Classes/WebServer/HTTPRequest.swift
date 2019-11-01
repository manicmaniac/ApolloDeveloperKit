//
//  HTTPRequest.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/3/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

/**
 * A Swifty wrapper for CFHTTPMessage instantiated as a request.
 */
class HTTPRequest {
    private let message: CFHTTPMessage

    init(message: CFHTTPMessage) {
        self.message = message
    }

    var url: URL {
        return CFHTTPMessageCopyRequestURL(message)!.takeRetainedValue() as URL
    }

    var method: String {
        return CFHTTPMessageCopyRequestMethod(message)!.takeRetainedValue() as String
    }

    var body: Data? {
        return CFHTTPMessageCopyBody(message)?.takeRetainedValue() as Data?
    }

    func value(forHTTPHeaderField field: String) -> String? {
        return CFHTTPMessageCopyHeaderFieldValue(message, field as CFString)?.takeRetainedValue() as String?
    }
}
