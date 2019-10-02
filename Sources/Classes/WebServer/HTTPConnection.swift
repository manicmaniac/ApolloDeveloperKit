//
//  HTTPConnection.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/3/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

protocol HTTPConnectionDelegate: class {
    func httpConnectionDidFinishReceiving(_ connection: HTTPConnection)
    func httpConnection(_ connection: HTTPConnection, didReceiveRequest request: HTTPRequest)
}

public class HTTPConnection {
    let fileHandle: FileHandle
    let message: CFHTTPMessage
    private weak var delegate: HTTPConnectionDelegate?
    private unowned let notificationCenter = NotificationCenter.default

    init(fileHandle: FileHandle, delegate: HTTPConnectionDelegate) {
        self.fileHandle = fileHandle
        self.message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true).takeRetainedValue()
        self.delegate = delegate
        self.notificationCenter.addObserver(self, selector: #selector(didReceiveFileHandleDataAvailableNotification(_:)), name: .NSFileHandleDataAvailable, object: fileHandle)
        fileHandle.waitForDataInBackgroundAndNotify()
    }

    func write(_ data: Data) {
        do {
            try self.fileHandle.writeData(data)
        } catch {
            self.close()
        }
    }

    func close() {
        stopReceiving()
        fileHandle.closeFile()
    }

    private func stopReceiving() {
        notificationCenter.removeObserver(self, name: .NSFileHandleDataAvailable, object: fileHandle)
        delegate?.httpConnectionDidFinishReceiving(self)
    }

    @objc private func didReceiveFileHandleDataAvailableNotification(_ notification: Notification) {
        let fileHandle = notification.object as! FileHandle
        let data = fileHandle.availableData
        guard !data.isEmpty else {
            return stopReceiving()
        }
        guard CFHTTPMessageAppendBytes(message, (data as NSData).bytes.assumingMemoryBound(to: UInt8.self), data.count) else {
            return close()
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
        stopReceiving()
        let request = HTTPRequest(message: message)
        delegate?.httpConnection(self, didReceiveRequest: request)
    }
}

extension HTTPConnection: Hashable {
    public static func == (lhs: HTTPConnection, rhs: HTTPConnection) -> Bool {
        return lhs.fileHandle == rhs.fileHandle
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(fileHandle)
    }
}
