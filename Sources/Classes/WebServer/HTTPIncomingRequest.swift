//
//  HTTPIncomingRequest.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/3/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

protocol HTTPIncomingRequestDelegate: class {
    func httpIncomingRequestDidStopReceiving(_ incomingRequest: HTTPIncomingRequest)
    func httpIncomingRequest(_ incomingRequest: HTTPIncomingRequest, didFinishWithRequest request: URLRequest, connection: HTTPConnection)
}

class HTTPIncomingRequest {
    let fileHandle: FileHandle
    let message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true).takeRetainedValue()
    private weak var delegate: HTTPIncomingRequestDelegate?
    private unowned let notificationCenter = NotificationCenter.default

    init(fileHandle: FileHandle, delegate: HTTPIncomingRequestDelegate) {
        self.fileHandle = fileHandle
        self.delegate = delegate
        self.notificationCenter.addObserver(self, selector: #selector(didReceiveFileHandleDataAvailableNotification(_:)), name: .NSFileHandleDataAvailable, object: fileHandle)
        fileHandle.waitForDataInBackgroundAndNotify()
    }

    func abort() {
        stopReceiving(closeFileHandle: true)
    }

    private var contentLength: Int? {
        assert(CFHTTPMessageIsHeaderComplete(message))
        let contentLengthString = CFHTTPMessageCopyHeaderFieldValue(message, "Content-Length" as CFString)?.takeRetainedValue() as String?
        return contentLengthString.flatMap(Int.init(_:))
    }

    private var bodyLength: Int {
        assert(CFHTTPMessageIsHeaderComplete(message))
        let body = CFHTTPMessageCopyBody(message)?.takeRetainedValue()
        return body.flatMap(CFDataGetLength) ?? 0
    }

    private func stopReceiving(closeFileHandle: Bool) {
        notificationCenter.removeObserver(self, name: .NSFileHandleDataAvailable, object: fileHandle)
        delegate?.httpIncomingRequestDidStopReceiving(self)
        if closeFileHandle {
            fileHandle.closeFile()
        }
    }

    private func resumeReceiving() {
        fileHandle.waitForDataInBackgroundAndNotify()
    }

    private func appendData(_ data: Data) -> Bool {
        let bytes = (data as NSData).bytes.assumingMemoryBound(to: UInt8.self)
        return CFHTTPMessageAppendBytes(message, bytes, data.count)
    }

    @objc private func didReceiveFileHandleDataAvailableNotification(_ notification: Notification) {
        let fileHandle = notification.object as! FileHandle
        let data = fileHandle.availableData
        guard !data.isEmpty else {
            return stopReceiving(closeFileHandle: false)
        }
        guard appendData(data) else {
            return stopReceiving(closeFileHandle: true)
        }
        guard CFHTTPMessageIsHeaderComplete(message) else {
            return resumeReceiving()
        }
        if let contentLength = contentLength, bodyLength < contentLength {
            return resumeReceiving()
        }
        stopReceiving(closeFileHandle: false)
        let request = convertToURLRequest(message: message)
        let connection = HTTPConnection(fileHandle: fileHandle)
        delegate?.httpIncomingRequest(self, didFinishWithRequest: request, connection: connection)
    }

    private func convertToURLRequest(message: CFHTTPMessage) -> URLRequest {
        assert(CFHTTPMessageIsRequest(message))
        let url = CFHTTPMessageCopyRequestURL(message)!.takeRetainedValue() as URL
        var request = URLRequest(url: url)
        request.httpMethod = CFHTTPMessageCopyRequestMethod(message)!.takeRetainedValue() as String
        request.allHTTPHeaderFields = CFHTTPMessageCopyAllHeaderFields(message)?.takeRetainedValue() as? [String: String]
        request.httpBody = CFHTTPMessageCopyBody(message)?.takeRetainedValue() as Data?
        return request
    }
}

// MARK: Hashable

extension HTTPIncomingRequest: Hashable {
    static func == (lhs: HTTPIncomingRequest, rhs: HTTPIncomingRequest) -> Bool {
        return lhs.fileHandle == rhs.fileHandle
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fileHandle)
    }
}
