//
//  HTTPServer.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/30/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

/**
 * The protocol to handle raw HTTP request the server receives.
 */
protocol HTTPServerDelegate: class {
    /**
     * Invoked when the server starts listening.
     *
     * - Parameter server: The server that starts.
     * - Parameter port: The port number to which the server is listening.
     */
    func server(_ server: HTTPServer, didStartListeningTo port: UInt16)

    /**
     * Invoked when the server receives a HTTP request.
     *
     * - Parameter server: The server receiving a HTTP request.
     * - Parameter request: A raw HTTP message including header and complete body.
     * - Parameter completion: A completion handler. You must call it when the response ends.
     */
    func server(_ server: HTTPServer, didReceiveRequest request: URLRequest, connection: HTTPConnection)
}

/**
 * `HTTPServer` is a minimal HTTP 1.1 server.
 *
 * The server works even after the app moves to the background for a while.
 *
 * - SeeAlso: https://www.cocoawithlove.com/2009/07/simple-extensible-http-server-in-cocoa.html
 */
class HTTPServer {
    weak var delegate: HTTPServerDelegate?

    /**
     * The URL where the server is established.
     */
    var serverURL: URL? {
        let address = (socket?.address as NSData?)?.bytes.assumingMemoryBound(to: sockaddr_in.self).pointee
        guard let port = address?.sin_port.bigEndian, let primaryIPAddress = primaryIPAddress else { return nil }
        return URL(string: "http://\(primaryIPAddress):\(port)/")
    }

    /**
     * A Boolean value indicating whether the server is running or not.
     */
    var isRunning: Bool {
        return socket != nil
    }

    private var socket: Socket?
    private var connections = Set<HTTPConnection>()

    private var primaryIPAddress: String? {
        #if targetEnvironment(simulator)
        // Assume en0 is Ethernet and en1 is WiFi since there is no way to use SystemConfiguration framework in iOS Simulator
        let expectedInterfaceNames: Set<String> = ["en0", "en1"]
        #else
        // Wi-Fi interface on iOS
        let expectedInterfaceNames: Set<String> = ["en0"]
        #endif
        return NetworkInterfaceList.current?.first { networkInterface in
            networkInterface.isUp && networkInterface.socketFamily == AF_INET && expectedInterfaceNames.contains(networkInterface.name)
        }?.ipv4Address
    }

    /**
     * Starts HTTP server listening on the given port.
     *
     * This method should be invoked on the main thread.
     *
     * - Parameter port: A port number. Avoid using well-known ports.
     * - Throws: `POSIXError` when an error occurred while setting up a socket.
     */
    func start(port: UInt16) throws {
        precondition(Thread.isMainThread)
        let socket = try Socket(protocolFamily: PF_INET, socketType: SOCK_STREAM, protocol: IPPROTO_TCP, callbackTypes: .acceptCallBack)
        socket.delegate = self
        try socket.setValue(1, for: SOL_SOCKET, option: SO_REUSEADDR)
        try socket.setValue(1, for: SOL_SOCKET, option: SO_NOSIGPIPE)
        var address = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                                  sin_family: sa_family_t(AF_INET),
                                  sin_port: port.bigEndian,
                                  sin_addr: in_addr(s_addr: INADDR_ANY.bigEndian),
                                  sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        let addressData = Data(bytes: &address, count: MemoryLayout.size(ofValue: address))
        try socket.setAddress(addressData)
        self.socket = socket
        socket.schedule(in: .current, forMode: .default)
    }

    /**
     * Starts HTTP server listening on a random port in the given range.
     *
     * This method should be invoked on the main thread.
     *
     * - Parameter ports: A range of ports. Avoid using well-known ports.
     * - Throws: `HTTPServerError` when an error occurred while setting up a socket.     *
     */
    func start<T: Collection>(randomPortIn ports: T) throws -> UInt16 where T.Element == UInt16 {
        precondition(Thread.isMainThread)
        precondition(!ports.isEmpty)
        var errorsByPort = [UInt16: Error]()
        for port in ports.shuffled() {
            do {
                try start(port: port)
                return port
            } catch let error {
                errorsByPort[port] = error
            }
        }
        throw HTTPServerError.multipleSocketErrorOccurred(errorsByPort)
    }

    /**
     * Stops the server from running.
     *
     * This method should be invoked on the main thread.
     */
    func stop() {
        precondition(Thread.isMainThread)
        guard isRunning else { return }
        for connection in connections {
            connection.close()
        }
        socket?.invalidate()
        socket = nil
    }
}

// MARK: HTTPConnectionDelegate

extension HTTPServer: HTTPConnectionDelegate {
    func httpConnection(_ connection: HTTPConnection, didReceive request: URLRequest) {
        delegate?.server(self, didReceiveRequest: request, connection: connection)
    }

    func httpConnectionWillClose(_ connection: HTTPConnection) {
        connections.remove(connection)
    }
}

// MARK: SocketDelegate

extension HTTPServer: SocketDelegate {
    func socket(_ socket: Socket, didAccept nativeHandle: CFSocketNativeHandle, address: Data) {
        guard let connection = try? HTTPConnection(httpVersion: kCFHTTPVersion1_1 as String, nativeHandle: nativeHandle) else {
            return
        }
        connection.delegate = self
        connection.schedule(in: .current, forMode: .default)
        connections.insert(connection)
    }

    func socket(_ socket: Socket, didReceive data: Data, address: Data) {
        assertionFailure("'data' callback must be disabled.")
    }
}
