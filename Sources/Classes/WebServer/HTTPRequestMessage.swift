//
//  HTTPRequestMessage.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/18/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

final class HTTPRequestMessage {
    private let message: CFHTTPMessage

    init() {
        self.message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true).takeRetainedValue()
    }

    var body: Data? {
        return CFHTTPMessageCopyBody(message)?.takeRetainedValue() as Data?
    }

    var version: String {
        return CFHTTPMessageCopyVersion(message).takeRetainedValue() as String
    }

    var isHeaderComplete: Bool {
        return CFHTTPMessageIsHeaderComplete(message)
    }

    var requestURL: URL? {
        return CFHTTPMessageCopyRequestURL(message)?.takeRetainedValue() as URL?
    }

    var requestMethod: String? {
        return CFHTTPMessageCopyRequestMethod(message)?.takeRetainedValue() as String?
    }

    var allHeaderFields: [String: String]? {
        return CFHTTPMessageCopyAllHeaderFields(message)?.takeRetainedValue() as? [String: String]
    }

    func value(for headerField: String) -> String? {
        return CFHTTPMessageCopyHeaderFieldValue(message, headerField as CFString)?.takeRetainedValue() as String?
    }

    func append(_ data: Data) -> Bool {
        return data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Bool in
            guard let baseAddress = bytes.bindMemory(to: UInt8.self).baseAddress else {
                // I think data.withUnsafeBytes doesn't pass a null pointer but just in case, ignore it.
                return true
            }
            return CFHTTPMessageAppendBytes(message, baseAddress, bytes.count)
        }
    }
}
