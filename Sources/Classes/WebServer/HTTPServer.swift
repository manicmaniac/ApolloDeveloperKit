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
        guard let port = port, let primaryIPAddress = primaryIPAddress else { return nil }
        return URL(string: "http://\(primaryIPAddress):\(port)/")
    }

    /**
     * A Boolean value indicating whether the server is running or not.
     */
    var isRunning: Bool {
        return socket != nil
    }

    private var port: UInt16?
    private var listeningHandle: FileHandle?
    private var socket: CFSocket?
    private var incomingRequests = Set<HTTPIncomingRequest>()
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
     * - Throws: `HTTPServerError` when an error occurred while setting up a socket.
     */
    func start(port: UInt16) throws {
        precondition(Thread.isMainThread)
        guard let socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, nil, nil) else {
            throw HTTPServerError.socketCreationFailed
        }

        var reuse = 1
        var noSigPipe = 1
        let fileDescriptor = CFSocketGetNative(socket)
        do {
            if setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int>.size)) != 0 {
                throw HTTPServerError.socketSetOptionFailed
            }
            if setsockopt(fileDescriptor, SOL_SOCKET, SO_NOSIGPIPE, &noSigPipe, socklen_t(MemoryLayout<Int>.size)) != 0 {
                throw HTTPServerError.socketSetOptionFailed
            }
            var address = sockaddr_in(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size),
                                      sin_family: sa_family_t(AF_INET),
                                      sin_port: port.bigEndian,
                                      sin_addr: in_addr(s_addr: INADDR_ANY.bigEndian),
                                      sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
            let addressData = Data(bytes: &address, count: MemoryLayout<sockaddr_in>.size)
            switch CFSocketSetAddress(socket, addressData as CFData) {
            case .success:
                break
            case .error:
                throw HTTPServerError.socketSetAddressFailed
            case .timeout:
                throw HTTPServerError.socketSetAddressTimeout
            @unknown default:
                throw HTTPServerError.socketSetAddressFailed
            }
        } catch let error {
            CFSocketInvalidate(socket)
            throw error
        }
        self.socket = socket
        self.port = port
        let listeningHandle = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: true)
        self.listeningHandle = listeningHandle
        NotificationCenter.default.addObserver(self, selector: #selector(receiveIncomingConnectionNotification(_:)), name: .NSFileHandleConnectionAccepted, object: listeningHandle)
        listeningHandle.acceptConnectionInBackgroundAndNotify()
        delegate?.server(self, didStartListeningTo: port)
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
        NotificationCenter.default.removeObserver(self, name: .NSFileHandleConnectionAccepted, object: nil)
        listeningHandle?.closeFile()
        listeningHandle = nil
        for incomingRequest in incomingRequests {
            incomingRequest.abort()
        }
        for connection in connections {
            connection.close()
        }
        if let socket = socket {
            CFSocketInvalidate(socket)
        }
        socket = nil
        port = nil
    }

    @objc private func receiveIncomingConnectionNotification(_ notification: Notification) {
        if let incomingFileHandle = notification.userInfo?[NSFileHandleNotificationFileHandleItem] as? FileHandle {
            let incomingRequest = HTTPIncomingRequest(httpVersion: kCFHTTPVersion1_1 as String, fileHandle: incomingFileHandle, delegate: self)
            incomingRequests.insert(incomingRequest)
        }
        listeningHandle?.acceptConnectionInBackgroundAndNotify()
    }
}

// MARK: HTTPIncomingRequestDelegate

extension HTTPServer: HTTPIncomingRequestDelegate {
    func httpIncomingRequestDidStopReceiving(_ incomingRequest: HTTPIncomingRequest) {
        incomingRequests.remove(incomingRequest)
    }

    func httpIncomingRequest(_ incomingRequest: HTTPIncomingRequest, didFinishWithRequest request: URLRequest, connection: HTTPConnection) {
        connection.delegate = self
        connections.insert(connection)
        delegate?.server(self, didReceiveRequest: request, connection: connection)
    }
}

// MARK: HTTPConnectionDelegate

extension HTTPServer: HTTPConnectionDelegate {
    func httpConnectionWillClose(_ connection: HTTPConnection) {
        connections.remove(connection)
    }
}
