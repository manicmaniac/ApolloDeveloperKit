//
//  SocketTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 9/24/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class SocketTests: XCTestCase {
    private var socket: Socket!
    private var delegateHandler: SocketDelegateHandler!
    private var address = sockaddr_in()

    override func setUp() {
        do {
            socket = try Socket(protocolFamily: PF_INET,
                                socketType: SOCK_STREAM,
                                protocol: IPPROTO_TCP,
                                callbackTypes: .acceptCallBack)
            delegateHandler = SocketDelegateHandler()
            socket.delegate = delegateHandler
            address = sockaddr_in(sin_len: UInt8(MemoryLayout<sockaddr_in>.size),
                                  sin_family: sa_family_t(AF_INET).bigEndian,
                                  sin_port: in_port_t(0).bigEndian,
                                  sin_addr: in_addr(s_addr: INADDR_ANY),
                                  sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        } catch let error {
            continueAfterFailure = false
            XCTFail(String(describing: error))
        }
    }

    override func tearDown() {
        socket.invalidate()
    }

    func testSetAddress() throws {
        let addressData = Data(bytes: &address, count: MemoryLayout.size(ofValue: address))
        try socket.setAddress(addressData)
        let actualAddress = socket.address.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> sockaddr_in in
            return bytes.load(as: sockaddr_in.self)
        }
        XCTAssertEqual(actualAddress.sin_len, address.sin_len)
        XCTAssertEqual(actualAddress.sin_family, address.sin_family)
        XCTAssertGreaterThan(actualAddress.sin_port, 1)
        XCTAssertEqual(actualAddress.sin_addr.s_addr, address.sin_addr.s_addr)
    }

    func testIsNonBlocking() {
        XCTAssertFalse(socket.isNonBlocking)
        socket.isNonBlocking = true
        XCTAssertTrue(socket.isNonBlocking)
        socket.isNonBlocking = false
        XCTAssertFalse( socket.isNonBlocking)
    }

    func testSetValue() throws {
        var value = UInt32(0)
        try socket.getValue(&value, for: SOL_SOCKET, option: SO_NOSIGPIPE)
        XCTAssertEqual(value, 0)
        try socket.setValue(1, for: SOL_SOCKET, option: SO_NOSIGPIPE)
        try socket.getValue(&value, for: SOL_SOCKET, option: SO_NOSIGPIPE)
        XCTAssertEqual(value, 1)
    }

    @available(macOS 10.11, *)
    func testSend_withTCPSocket() throws {
        let addressData = Data(bytes: &address, count: MemoryLayout.size(ofValue: address))
        try socket.setAddress(addressData)
        let sentData = Data("foo".utf8)
        let expectationToWrite = expectation(description: "Data should be written.")
        delegateHandler.socketDidAcceptCallback = { socket, nativeHandle, address in
            defer { expectationToWrite.fulfill() }
            let writtenSize = sentData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Int in
                return write(nativeHandle, bytes.baseAddress!, bytes.count)
            }
            XCTAssertNotEqual(writtenSize, -1)
        }
        socket.schedule(in: .current, forMode: .default)
        let port = socket.address.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Int in
            return Int(bytes.load(as: sockaddr_in.self).sin_port.bigEndian)
        }
        let session = URLSession(configuration: .test)
        defer { session.invalidateAndCancel() }
        let task = session.streamTask(withHostName: "127.0.0.1", port: port)
        task.resume()
        wait(for: [expectationToWrite], timeout: 0.25)
        let expectationToRead = expectation(description: "Read callback should be called.")
        task.readData(ofMinLength: sentData.count, maxLength: sentData.count, timeout: 0) { data, atEOF, error in
            defer { expectationToRead.fulfill() }
            XCTAssertEqual(data, sentData)
            XCTAssertNil(error)
            XCTAssertFalse(atEOF)
        }
        task.captureStreams()
        waitForExpectations(timeout: 0.25)
    }

    func testSend_hugeDataWithUNIXDomainSocket() throws {
        var nativeHandles = [CFSocketNativeHandle](repeating: 0, count: 2)
        nativeHandles.withUnsafeMutableBufferPointer { buffer in
            XCTAssertNotEqual(socketpair(PF_UNIX, SOCK_STREAM, 0, buffer.baseAddress!), -1)
        }
        let server = try Socket(nativeHandle: nativeHandles[0], callbackTypes: [])
        defer { server.invalidate() }
        let client = try Socket(nativeHandle: nativeHandles[1], callbackTypes: [])
        defer { client.invalidate() }
        let sentData = Data("foo".utf8)
        let success = try client.send(data: sentData, timeout: 1)
        XCTAssertTrue(success)
        var buffer = [CChar](repeating: 0, count: sentData.count)
        XCTAssertNotEqual(recv(server.nativeHandle, &buffer, buffer.count, 0), -1)
        let receivedData = Data(bytes: &buffer, count: buffer.count)
        XCTAssertEqual(receivedData, sentData)
    }
}

private class SocketDelegateHandler: SocketDelegate {
    var socketDidAcceptCallback: ((Socket, CFSocketNativeHandle, Data) -> Void)?
    var socketDidReceiveCallback: ((Socket, Data, Data) -> Void)?
    var socketDidBecomeWritableCallback: ((Socket) -> Void)?

    func socket(_ socket: Socket, didAccept nativeHandle: CFSocketNativeHandle, address: Data) {
        socketDidAcceptCallback?(socket, nativeHandle, address)
    }

    func socket(_ socket: Socket, didReceive data: Data, address: Data) {
        socketDidReceiveCallback?(socket, data, address)
    }

    func socketDidBecomeWritable(_ socket: Socket) {
        socketDidBecomeWritableCallback?(socket)
    }
}
