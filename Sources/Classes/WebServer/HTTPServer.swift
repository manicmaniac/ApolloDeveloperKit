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
    private enum State {
        case idle
        case starting
        case running(port: UInt16)
        case stopping
    }
    weak var delegate: HTTPServerDelegate?

    /**
     * The URL where the server is established.
     */
    var serverURL: URL? {
        guard case .running(port: let port) = state, let primaryIPAddress = primaryIPAddress else { return nil }
        return URL(string: "http://\(primaryIPAddress):\(port)/")
    }

    /**
     * A Boolean value indicating whether the server is running or not.
     */
    var isRunning: Bool {
        if case .running = state {
            return true
        }
        return false
    }

    private let httpVersion = kCFHTTPVersion1_1 as String
    private var state = State.idle
    private var listeningHandle: FileHandle?
    private var socket: CFSocket?
    private var incomingRequests = Set<HTTPIncomingRequest>()
    private var connections = Set<HTTPConnection>()

    private var primaryIPAddress: String? {
        #if targetEnvironment(simulator)
        // Assume en0 is Ethernet and en1 is WiFi since there is no way to use SystemConfiguration framework in iOS Simulator
        let expectedInterfaceNames = ["en0", "en1"]
        #else
        // Wi-Fi interface on iOS
        let expectedInterfaceNames = ["en0"]
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
     * - Throws: `HTTPServerError` when an error occured while setting up a socket.
     */
    func start(port: UInt16) throws {
        state = .starting
        guard let socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, 0, nil, nil) else {
            throw HTTPServerError.socketCreationFailed
        }
        self.socket = socket

        var reuse = 1
        let fileDescriptor = CFSocketGetNative(socket)
        do {
            if setsockopt(fileDescriptor, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int>.size)) != 0 {
                throw HTTPServerError.socketSetOptionFailed
            }
            var noSigPipe = 1
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
        let listeningHandle = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: true)
        self.listeningHandle = listeningHandle
        NotificationCenter.default.addObserver(self, selector: #selector(receiveIncomingConnectionNotification(_:)), name: .NSFileHandleConnectionAccepted, object: listeningHandle)
        listeningHandle.acceptConnectionInBackgroundAndNotify()
        state = .running(port: port)
        delegate?.server(self, didStartListeningTo: port)
    }

    /**
     * Starts HTTP server listening on a random port in the given range.
     *
     * This method should be invoked on the main thread.
     *
     * - Parameter ports: A range of ports. Avoid using well-known ports.
     * - Throws: `HTTPServerError` when an error occured while setting up a socket.     *
     */
    func start<T: Collection>(randomPortIn ports: T) throws -> UInt16 where T.Element == UInt16 {
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
        guard case .running = state else {
            return
        }
        state = .stopping
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
        state = .idle
    }

    @objc private func receiveIncomingConnectionNotification(_ notification: Notification) {
        if let incomingFileHandle = notification.userInfo?[NSFileHandleNotificationFileHandleItem] as? FileHandle {
            let incomingRequest = HTTPIncomingRequest(httpVersion: httpVersion, fileHandle: incomingFileHandle, delegate: self)
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
