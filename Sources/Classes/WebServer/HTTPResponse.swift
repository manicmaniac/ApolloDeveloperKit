//
//  HTTPResponse.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 9/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

/**
 * A Swifty wrapper for CFHTTPMessage instantiated as a resposne.
 */
struct HTTPResponse {
    let message: CFHTTPMessage

    init(statusCode: Int, httpVersion: CFString) {
        message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, nil, httpVersion).takeRetainedValue()
    }

    init(httpURLResponse: HTTPURLResponse, body: Data?, httpVersion: CFString) {
        self.init(statusCode: httpURLResponse.statusCode, httpVersion: httpVersion)
        for case let (field as String, value as String) in httpURLResponse.allHeaderFields {
            setValue(value, forHTTPHeaderField: field)
        }
        if let body = body {
            setBody(body)
        }
    }

    func setValue(_ value: String?, forHTTPHeaderField field: String) {
        CFHTTPMessageSetHeaderFieldValue(message, field as CFString, value as CFString?)
    }

    func setBody(_ body: Data) {
        CFHTTPMessageSetBody(message, body as CFData)
    }

    func serialize() -> Data? {
        return CFHTTPMessageCopySerializedMessage(message)?.takeUnretainedValue() as Data?
    }
}
