//
//  HTTPConnection.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/3/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

protocol HTTPConnectionDelegate: class {
    func httpConnection(_ connection: HTTPConnection, didReceive request: URLRequest)
    func httpConnectionWillClose(_ connection: HTTPConnection)
    func httpConnection(_ connection: HTTPConnection, didFailToHandle request: URLRequest, error: Error)
}

/**
 * `HTTPConnection` represents an individual connection of HTTP transmissions.
 */
final class HTTPConnection {
    let httpVersion: String
    weak var delegate: HTTPConnectionDelegate?
    private let incomingRequest = HTTPRequestMessage()
    private let socket: Socket

    init(httpVersion: String, nativeHandle: CFSocketNativeHandle) throws {
        self.httpVersion = httpVersion
        let socket = try Socket(nativeHandle: nativeHandle, callbackTypes: .dataCallBack)
        self.socket = socket
        try socket.setValue(1, for: SOL_SOCKET, option: SO_NOSIGPIPE)
        socket.delegate = self
    }

    func schedule(in runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        socket.schedule(in: runLoop, forMode: mode)
    }

    func write(chunkedResponse: HTTPChunkedResponse) {
        write(data: chunkedResponse.data)
    }

    func write(response: HTTPURLResponse, body: Data?) {
        let message = HTTPResponseMessage(httpURLResponse: response, httpVersion: httpVersion)
        message.setBody(body)
        write(message: message)
    }

    func write(message: HTTPResponseMessage) {
        assert(message.isHeaderComplete)
        guard let data = message.serialize() else {
            return
        }
        write(data: data)
    }

    func write(data: Data) {
        do {
            try socket.send(data: data, timeout: 60)
        } catch {
            close()
        }
    }

    func close() {
        delegate?.httpConnectionWillClose(self)
        socket.invalidate()
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
            return close()
        }
        guard incomingRequest.isHeaderComplete else {
            return
        }
        guard incomingRequest.value(for: "Transfer-Encoding")?.lowercased() != "chunked" else {
            // As chunked encoding is not implemented yet, raise an error to notify the delegate.
            var request = URLRequest(httpMessage: incomingRequest)
            request.httpBody = nil
            delegate?.httpConnection(self, didFailToHandle: request, error: HTTPServerError.unsupportedBodyEncoding("chunked"))
            return
        }
        let contentLength = incomingRequest.body?.count ?? 0
        let expectedContentLength = incomingRequest.value(for: "Content-Length").flatMap(Int.init(_:)) ?? 0
        guard contentLength >= expectedContentLength else {
            return
        }
        socket.disableCallBacks(.dataCallBack)
        let request = URLRequest(httpMessage: incomingRequest)
        delegate?.httpConnection(self, didReceive: request)
    }
}
