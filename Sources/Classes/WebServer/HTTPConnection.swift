//
//  HTTPConnection.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/3/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

protocol HTTPConnectionDelegate: class {
    func httpConnectionWillClose(_ connection: HTTPConnection)
}

/**
 * `HTTPConnection` represents an individual connection of HTTP transmissions.
 */
class HTTPConnection {
    let httpVersion: String
    weak var delegate: HTTPConnectionDelegate?
    private let fileHandle: FileHandle
    private let lock = NSRecursiveLock()
    private var isFileHandleOpen = true

    init(httpVersion: String, fileHandle: FileHandle) {
        self.httpVersion = httpVersion
        self.fileHandle = fileHandle
    }

    func write(chunkedResponse: HTTPChunkedResponse) {
        write(data: chunkedResponse.data)
    }

    func write(response: HTTPURLResponse, body: Data?) {
        let message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, response.statusCode, nil, httpVersion as CFString).takeRetainedValue()
        for case (let headerField as CFString, let value as CFString) in response.allHeaderFields {
            CFHTTPMessageSetHeaderFieldValue(message, headerField, value)
        }
        CFHTTPMessageSetBody(message, (body ?? Data()) as CFData)
        write(message: message)
    }

    func write(message: CFHTTPMessage) {
        assert(!CFHTTPMessageIsRequest(message))
        assert(CFHTTPMessageIsHeaderComplete(message))
        guard let data = CFHTTPMessageCopySerializedMessage(message)?.takeRetainedValue() as Data? else {
            return
        }
        write(data: data)
    }

    func write(data: Data) {
        lock.lock()
        defer { lock.unlock() }
        guard isFileHandleOpen else { return }
        do {
            try fileHandle.writeData(data)
        } catch {
            close()
        }
    }

    func close() {
        lock.lock()
        defer { lock.unlock() }
        guard isFileHandleOpen else { return }
        delegate?.httpConnectionWillClose(self)
        fileHandle.closeFile()
        isFileHandleOpen = false
    }
}

// MARK: Hashable

extension HTTPConnection: Hashable {
    static func == (lhs: HTTPConnection, rhs: HTTPConnection) -> Bool {
        return lhs.fileHandle == rhs.fileHandle
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fileHandle)
    }
}
