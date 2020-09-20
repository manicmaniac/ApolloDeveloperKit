//
//  HTTPServer.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/30/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation
#if os(macOS)
import SystemConfiguration
#endif

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
     * - Parameter context: A raw HTTP request context including header and complete body.
     */
    func server(_ server: HTTPServer, didReceiveRequest context: HTTPRequestContext)

    /**
     * Invoked when a server error occurs in a HTTP connection.
     *
     * - Parameter server: The server receiving a HTTP request.
     * - Parameter context: An HTTP request context which caused the error. It must not have body part.
     * - Parameter error: An error object describing why the server couldn't handle the request.     *
     */
    func server(_ server: HTTPServer, didFailToHandle context: HTTPRequestContext, error: Error)
}

/**
 * `HTTPServer` is a minimal HTTP 1.1 server.
 *
 * The server works even after the app moves to the background for a while.
 *
 * - SeeAlso: https://www.cocoawithlove.com/2009/07/simple-extensible-http-server-in-cocoa.html
 */
final class HTTPServer {
    weak var delegate: HTTPServerDelegate?
    private var socket: Socket?
    private var connections = Set<HTTPConnection>()

    /**
     * The URL where the server is established.
     *
     * Only returns resolved hostname in IPv4 format.
     * - SeeAlso: `HTTPServer.serverURLs`
     */
    var serverURL: URL? {
        guard let port = port, let primaryIPAddress = primaryIPv4Address else { return nil }
        return URL(string: "http://\(primaryIPAddress):\(port)/")
    }

    /**
     * The possible URLs where the server is established.
     *
     * The hostname may contain resolved IPv4 / IPv6 format.
     */
    var serverURLs: [URL] {
        guard let port = port else { return [] }
        let hosts = ipAddresses + [hostname].compactMap { $0 }
        return hosts.compactMap { URL(string: "http://\($0):\(port)/") }
    }

    /**
     * A Boolean value indicating whether the server is running or not.
     */
    var isRunning: Bool {
        return socket != nil
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
        self.socket = try withAddressInfo(port: port) { addressInfo in
            let socket = try Socket(protocolFamily: addressInfo.ai_family,
                                    socketType: addressInfo.ai_socktype,
                                    protocol: addressInfo.ai_protocol,
                                    callbackTypes: .acceptCallBack)
            socket.delegate = self
            try socket.setValue(1, for: SOL_SOCKET, option: SO_REUSEADDR)
            try socket.setValue(1, for: SOL_SOCKET, option: SO_NOSIGPIPE)
            socket.isNonBlocking = true
            let addressData = Data(bytes: addressInfo.ai_addr, count: Int(addressInfo.ai_addrlen))
            try socket.setAddress(addressData)
            socket.schedule(in: .current, forMode: .default)
            return socket
        }
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

    private var port: UInt16? {
        let address = socket?.address.withUnsafeBytes { $0.load(as: sockaddr_in.self) }
        return address?.sin_port.bigEndian
    }

    private var hostname: String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXHOSTNAMELEN))
        errno = 0
        guard gethostname(&buffer, buffer.count) != -1 else {
            return nil
        }
        return String(cString: buffer)
    }

    private var ipAddresses: [String] {
        guard let iterator = try? InterfaceAddressIterator() else { return [] }
        let families = Set([AF_INET, AF_INET6].map(sa_family_t.init(_:)))
        let names = primaryNetworkInterfaceNames
        return IteratorSequence(iterator)
            .lazy
            .filter { $0.isUp && families.contains($0.socketFamily) && names.contains($0.name) }
            .compactMap { address in
                if address.socketFamily == AF_INET6 {
                    return address.hostName.flatMap { "[\($0)]" }
                } else {
                    return address.hostName
                }
        }
    }

    private var primaryIPv4Address: String? {
        guard let iterator = try? InterfaceAddressIterator() else { return nil }
        let expectedInterfaceNames = primaryNetworkInterfaceNames
        return IteratorSequence(iterator).first {
            $0.isUp && $0.socketFamily == AF_INET && expectedInterfaceNames.contains($0.name)
        }?.hostName
    }

    private var primaryNetworkInterfaceNames: Set<String> {
        #if os(macOS)
        let key = SCDynamicStoreKeyCreateNetworkGlobalEntity(kCFAllocatorDefault, kSCDynamicStoreDomainState, kSCEntNetIPv4)
        if let store = SCDynamicStoreCreate(kCFAllocatorDefault, "ApolloDeveloperKit" as CFString, nil, nil),
            let info = SCDynamicStoreCopyValue(store, key) as? [CFString: Any],
            let name = info[kSCDynamicStorePropNetPrimaryInterface] as? String {
            return [name]
        }
        return ["lo0"]
        #elseif targetEnvironment(simulator)
        // Assume en0 is Ethernet and en1 is WiFi since there is no way to use SystemConfiguration framework in iOS Simulator
        return ["en0", "en1"]
        #else
        // Wi-Fi interface on iOS
        return ["en0"]
        #endif
    }

    private func withAddressInfo<T>(port: UInt16, procedure: (addrinfo) throws -> T) throws -> T {
        var hints = addrinfo(ai_flags: AI_PASSIVE | AI_NUMERICSERV,
                             ai_family: PF_INET6,
                             ai_socktype: SOCK_STREAM,
                             ai_protocol: IPPROTO_TCP,
                             ai_addrlen: 0,
                             ai_canonname: nil,
                             ai_addr: nil,
                             ai_next: nil)
        var pointer: UnsafeMutablePointer<addrinfo>!
        if let code = AddressInfoErrorCode(rawValue: getaddrinfo(nil, String(port), &hints, &pointer)) {
            throw AddressInfoError(code)
        }
        defer { freeaddrinfo(pointer) }
        return try procedure(pointer.pointee)
    }
}

// MARK: HTTPConnectionDelegate

extension HTTPServer: HTTPConnectionDelegate {
    func httpConnection(_ connection: HTTPConnection, didReceive request: HTTPRequestMessage) {
        let context = HTTPRequestContext(request: request, connection: connection)
        delegate?.server(self, didReceiveRequest: context)
    }

    func httpConnectionWillClose(_ connection: HTTPConnection) {
        connections.remove(connection)
    }

    func httpConnection(_ connection: HTTPConnection, didFailToHandle request: HTTPRequestMessage, error: Error) {
        let context = HTTPRequestContext(request: request, connection: connection)
        delegate?.server(self, didFailToHandle: context, error: error)
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

    func socketDidBecomeWritable(_ socket: Socket) {
        assertionFailure("'write' callback must be disabled.")
    }
}
