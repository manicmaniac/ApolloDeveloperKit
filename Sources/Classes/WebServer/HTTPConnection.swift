//
//  HTTPConnection.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/3/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

protocol HTTPConnectionDelegate: class {
    func httpConnection(_ connection: HTTPConnection, didReceive request: HTTPRequestMessage)
    func httpConnectionWillClose(_ connection: HTTPConnection)
    func httpConnection(_ connection: HTTPConnection, didFailToHandle request: HTTPRequestMessage, error: Error)
}

/**
 * `HTTPConnection` represents an individual connection of HTTP transmissions.
 */
final class HTTPConnection {
    private enum Event {
        case write(Data)
        case close
    }

    let httpVersion: String
    weak var delegate: HTTPConnectionDelegate?
    private let incomingRequest = HTTPRequestMessage()
    private let socket: Socket
    private var eventQueue = ArraySlice<Event>()

    init(httpVersion: String, nativeHandle: CFSocketNativeHandle) throws {
        self.httpVersion = httpVersion
        let socket = try Socket(nativeHandle: nativeHandle, callbackTypes: [.dataCallBack, .writeCallBack])
        self.socket = socket
        socket.isNonBlocking = true
        try socket.setValue(1, for: SOL_SOCKET, option: SO_NOSIGPIPE)
        socket.delegate = self
    }

    func schedule(in runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        socket.schedule(in: runLoop, forMode: mode)
    }
}

// MARK: HTTPOutputStream

extension HTTPConnection: HTTPOutputStream {
    func write(data: Data) {
        eventQueue.append(.write(data))
        tryFlush()
    }

    func writeAndClose(contentsOf url: URL) throws {
        let fileHandle = try FileHandle(forReadingFrom: url)
        NotificationCenter.default.addObserver(self, selector: #selector(fileHandleDidReadToEndOfFileInBackground(_:)), name: .NSFileHandleReadToEndOfFileCompletion, object: fileHandle)
        fileHandle.readToEndOfFileInBackgroundAndNotify()
    }

    func close() {
        eventQueue.append(.close)
        tryFlush()
    }

    func closeImmediately() {
        delegate?.httpConnectionWillClose(self)
        socket.invalidate()
    }

    @objc private func fileHandleDidReadToEndOfFileInBackground(_ notification: Notification) {
        defer {
            NotificationCenter.default.removeObserver(self, name: .NSFileHandleReadToEndOfFileCompletion, object: notification.object)
        }
        guard let fileHandle = notification.object as? FileHandle,
              let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data
        else { return }
        fileHandle.closeFile()
        write(data: data)
        close()
    }

    private func tryFlush() {
        switch eventQueue.first {
        case .write(let data)?:
            if sendOrClose(data: data, timeout: 0) {
                eventQueue = eventQueue[eventQueue.startIndex.advanced(by: 1)..<eventQueue.endIndex]
                tryFlush()
            }
        case .close?:
            closeImmediately()
        case nil:
            break
        }
    }

    private func sendOrClose(data: Data, timeout: TimeInterval) -> Bool {
        do {
            return try socket.send(data: data, timeout: timeout)
        } catch {
            closeImmediately()
            return false
        }
    }
}

// MARK: Hashable

extension HTTPConnection: Hashable {
    static func == (lhs: HTTPConnection, rhs: HTTPConnection) -> Bool {
        return lhs.socket == rhs.socket
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(socket)
    }
}

// MARK: SocketDelegate

extension HTTPConnection: SocketDelegate {
    func socket(_ socket: Socket, didAccept nativeHandle: CFSocketNativeHandle, address: Data) {
        assertionFailure("'accept' callback must be disabled.")
    }

    func socket(_ socket: Socket, didReceive data: Data, address: Data) {
        guard !data.isEmpty, incomingRequest.append(data) else {
            return closeImmediately()
        }
        guard incomingRequest.isHeaderComplete else {
            return
        }
        guard incomingRequest.value(for: "Transfer-Encoding")?.lowercased() != "chunked" else {
            // As chunked encoding is not implemented yet, raise an error to notify the delegate.
            delegate?.httpConnection(self, didFailToHandle: incomingRequest, error: HTTPServerError.unsupportedBodyEncoding("chunked"))
            return
        }
        let contentLength = incomingRequest.body?.count ?? 0
        let expectedContentLength = incomingRequest.value(for: "Content-Length").flatMap(Int.init(_:)) ?? 0
        guard contentLength >= expectedContentLength else {
            return
        }
        socket.disableCallBacks(.dataCallBack)
        delegate?.httpConnection(self, didReceive: incomingRequest)
    }

    func socketDidBecomeWritable(_ socket: Socket) {
        tryFlush()
    }
}
