//
//  HTTPResponseMessage.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/18/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

final class HTTPResponseMessage {
    private let message: CFHTTPMessage

    init(statusCode: Int, statusDescription: String? = nil, httpVersion: String) {
        self.message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, statusDescription as CFString?, httpVersion as CFString).takeRetainedValue()
    }

    var isHeaderComplete: Bool {
        return CFHTTPMessageIsHeaderComplete(message)
    }

    func setBody(_ body: Data?) {
        CFHTTPMessageSetBody(message, (body ?? Data()) as CFData)
    }

    func setValue(_ value: String, for headerField: String) {
        CFHTTPMessageSetHeaderFieldValue(message, headerField as CFString, value as CFString)
    }

    func serialize() -> Data? {
        return CFHTTPMessageCopySerializedMessage(message)?.takeRetainedValue() as Data?
    }
}
