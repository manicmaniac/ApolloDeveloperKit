//
//  HTTPServer.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/30/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import UIKit

/**
 * The protocol to handle raw HTTP request the server receives.
 */
public protocol HTTPRequestHandler: class {
    /**
     * Invoked when the server receives a HTTP request.
     *
     * - Parameter server: The server receiving a HTTP request.
     * - Parameter request: A raw HTTP message including header and complete body.
     * - Parameter fileHandle: A file handle wrapping the underlying socket.
     * - Parameter completion: A completion handler. You must call it when the response ends.
     */
    func server(_ server: HTTPServer, didReceiveRequest request: CFHTTPMessage, fileHandle: FileHandle, completion: @escaping () -> Void)
}

/**
 * `HTTPServer` is a minimal HTTP 1.1 server.
 *
 * The server works even after the app moves to the background for a while.
 *
 * - SeeAlso: https://www.cocoawithlove.com/2009/07/simple-extensible-http-server-in-cocoa.html
 */
public class HTTPServer {
    private enum State {
        case idle
        case starting
        case running(port: UInt16)
        case stopping
    }
    let httpVersion = kCFHTTPVersion1_1
    weak var requestHandler: HTTPRequestHandler?

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

    private var state = State.idle
    private var listeningHandle: FileHandle?
    private var socket: CFSocket?
    private var incomingRequests = [FileHandle: CFHTTPMessage]()
    private var backgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid

    private var primaryIPAddress: String? {
        var addrs: UnsafeMutablePointer<ifaddrs>?
        if withUnsafeMutablePointer(to: &addrs, getifaddrs) >= 0 {
            defer { freeifaddrs(addrs) }
            let ifap = addrs
            while let ifap = ifap {
                if (ifap.pointee.ifa_flags & UInt32(IFF_UP) == 1) && (ifap.pointee.ifa_addr.pointee.sa_family == AF_INET) {
                    return primaryIPAddress(from: ifap.pointee.ifa_addr)
                }
                ifap.moveAssign(from: ifap.pointee.ifa_next, count: 1)
            }
        }
        return nil
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
            }
            if listen(fileDescriptor, 16) != 0 {
                throw HTTPServerError.socketListenFailed
            }
        } catch let error {
            CFSocketInvalidate(socket)
            throw error
        }
        let listeningHandle = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: true)
        self.listeningHandle = listeningHandle
        NotificationCenter.default.addObserver(self, selector: #selector(receiveIncomingConnectionNotification(_:)), name: .NSFileHandleConnectionAccepted, object: listeningHandle)
        listeningHandle.acceptConnectionInBackgroundAndNotify()
        startBackgroundTaskIfNeeded()
        state = .running(port: port)
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
        for incomingFileHandle in incomingRequests.keys {
            stopReceiving(for: incomingFileHandle, close: true)
        }
        if let socket = socket {
            CFSocketInvalidate(socket)
        }
        socket = nil
        state = .idle
    }

    private func stopReceiving(for incomingFileHandle: FileHandle, close closeFileHandle: Bool) {
        if closeFileHandle {
            incomingFileHandle.closeFile()
        }
        NotificationCenter.default.removeObserver(self, name: .NSFileHandleDataAvailable, object: incomingFileHandle)
        incomingRequests.removeValue(forKey: incomingFileHandle)
    }

    private func primaryIPAddress(from sockaddr: UnsafePointer<sockaddr>) -> String? {
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(NI_MAXHOST))
        defer { buffer.deallocate() }
        guard getnameinfo(sockaddr, socklen_t(sockaddr.pointee.sa_len), buffer, socklen_t(NI_MAXHOST), nil, 0, NI_NUMERICHOST | NI_NOFQDN) == 0 else {
            return nil
        }
        return String(cString: buffer, encoding: .ascii)
    }

    private func startBackgroundTaskIfNeeded() {
        precondition(Thread.isMainThread)
        guard backgroundTaskIdentifier == .invalid else { return }
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = .invalid
        }
    }

    @objc private func receiveIncomingConnectionNotification(_ notification: Notification) {
        if let incomingFileHandle = notification.userInfo?[NSFileHandleNotificationFileHandleItem] as? FileHandle {
            let message = CFHTTPMessageCreateEmpty(kCFAllocatorDefault, true)
            incomingRequests[incomingFileHandle] = message.autorelease().takeUnretainedValue()
            NotificationCenter.default.addObserver(self, selector: #selector(receiveIncomingDataNotification(_:)), name: .NSFileHandleDataAvailable, object: incomingFileHandle)
            incomingFileHandle.waitForDataInBackgroundAndNotify()
        }
        listeningHandle?.acceptConnectionInBackgroundAndNotify()
    }

    @objc private func receiveIncomingDataNotification(_ notification: Notification) {
        guard let incomingFileHandle = notification.object as? FileHandle else { return }
        var data = incomingFileHandle.availableData
        guard !data.isEmpty else {
            return stopReceiving(for: incomingFileHandle, close: false)
        }
        guard let incomingRequest = incomingRequests[incomingFileHandle] else {
            return stopReceiving(for: incomingFileHandle, close: true)
        }
        guard data.withUnsafeBytes({ bytes in CFHTTPMessageAppendBytes(incomingRequest, bytes, data.count) }) else {
            return stopReceiving(for: incomingFileHandle, close: true)
        }
        guard CFHTTPMessageIsHeaderComplete(incomingRequest) else {
            return incomingFileHandle.waitForDataInBackgroundAndNotify()
        }
        let contentLengthString = CFHTTPMessageCopyHeaderFieldValue(incomingRequest, "Content-Length" as CFString)?.takeRetainedValue() as String?
        if let contentLength = contentLengthString.flatMap(Int.init(_:)) {
            let body = CFHTTPMessageCopyBody(incomingRequest)?.takeRetainedValue()
            let bodyLength = body.flatMap(CFDataGetLength) ?? 0
            if bodyLength < contentLength {
                return incomingFileHandle.waitForDataInBackgroundAndNotify()
            }
        }
        defer { stopReceiving(for: incomingFileHandle, close: false) }
        requestHandler?.server(self, didReceiveRequest: incomingRequest, fileHandle: incomingFileHandle) { [weak self] in
            self?.stopReceiving(for: incomingFileHandle, close: true)
        }
    }
}
