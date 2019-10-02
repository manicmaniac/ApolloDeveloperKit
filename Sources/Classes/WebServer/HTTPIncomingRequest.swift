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
    func httpIncomingRequest(_ incomingRequest: HTTPIncomingRequest, didFinishWithRequest request: HTTPRequest, connection: HTTPConnection)
}

public class HTTPIncomingRequest {
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

    private func stopReceiving(closeFileHandle: Bool) {
        notificationCenter.removeObserver(self, name: .NSFileHandleDataAvailable, object: fileHandle)
        delegate?.httpIncomingRequestDidStopReceiving(self)
        if closeFileHandle {
            fileHandle.closeFile()
        }
    }

    @objc private func didReceiveFileHandleDataAvailableNotification(_ notification: Notification) {
        let fileHandle = notification.object as! FileHandle
        let data = fileHandle.availableData
        guard !data.isEmpty else {
            return stopReceiving(closeFileHandle: false)
        }
        guard CFHTTPMessageAppendBytes(message, (data as NSData).bytes.assumingMemoryBound(to: UInt8.self), data.count) else {
            return stopReceiving(closeFileHandle: true)
        }
        guard CFHTTPMessageIsHeaderComplete(message) else {
            return fileHandle.waitForDataInBackgroundAndNotify()
        }
        let contentLengthString = CFHTTPMessageCopyHeaderFieldValue(message, "Content-Length" as CFString)?.takeRetainedValue() as String?
        if let contentLength = contentLengthString.flatMap(Int.init(_:)) {
            let body = CFHTTPMessageCopyBody(message)?.takeRetainedValue()
            let bodyLength = body.flatMap(CFDataGetLength) ?? 0
            guard bodyLength >= contentLength else {
                return fileHandle.waitForDataInBackgroundAndNotify()
            }
        }
        stopReceiving(closeFileHandle: false)
        let request = HTTPRequest(message: message)
        let connection = HTTPConnection(fileHandle: fileHandle)
        delegate?.httpIncomingRequest(self, didFinishWithRequest: request, connection: connection)
    }
}

// MARK: Hashable

extension HTTPIncomingRequest: Hashable {
    public static func == (lhs: HTTPIncomingRequest, rhs: HTTPIncomingRequest) -> Bool {
        return lhs.fileHandle == rhs.fileHandle
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(fileHandle)
    }
}
