//
//  HTTPConnectionTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/6/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class HTTPConnectionTests: XCTestCase {
    private let httpVersion = kCFHTTPVersion1_1 as String
    private var writerFileDescriptor: Int32!
    private var readerFileDescriptor: Int32!

    override func setUpWithError() throws {
        var fileDescriptors = [Int32](repeating: 0, count: 2)
        errno = 0
        guard socketpair(AF_UNIX, SOCK_STREAM, 0, &fileDescriptors) == 0 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
        writerFileDescriptor = fileDescriptors[0]
        readerFileDescriptor = fileDescriptors[1]
    }

    override func tearDownWithError() throws {
        for case let handle? in [writerFileDescriptor, readerFileDescriptor] {
            errno = 0
            guard close(handle) == 0 || errno == EBADF else {
                throw POSIXError(POSIXErrorCode(rawValue: errno)!)
            }
        }
    }

    func testWrite() throws {
        let connection = try HTTPConnection(httpVersion: httpVersion, nativeHandle: writerFileDescriptor)
        connection.write(data: httpGetRequestMessage)
        connection.close()
        let fileHandle = FileHandle(fileDescriptor: readerFileDescriptor)
        let data: Data?
        if #available(macOS 10.15.4, *, iOS 13.4, *) {
            data = try fileHandle.read(upToCount: httpGetRequestMessage.count)
        } else {
            data = fileHandle.readData(ofLength: httpGetRequestMessage.count)
        }
        XCTAssertEqual(data, httpGetRequestMessage)
    }

    func testWrite_threadSafety() throws {
        let connection = try HTTPConnection(httpVersion: httpVersion, nativeHandle: writerFileDescriptor)
        let iterations = 100
        for _ in 0..<iterations {
            let thread: Thread
            if #available(macOS 10.12, *, iOS 10, *) {
                thread = Thread { [unowned self] in
                    self.writeData(into: connection)
                }
            } else {
                thread = Thread(target: self, selector: #selector(writeData(into:)), object: connection)
            }
            expectation(forNotification: .NSThreadWillExit, object: thread)
            thread.start()
        }
        waitForExpectations(timeout: 0.5)
        connection.close()
        let fileHandle = FileHandle(fileDescriptor: readerFileDescriptor)
        let expectedBytesCount = httpGetRequestMessage.count * iterations
        let data: Data?
        if #available(macOS 10.15.4, *, iOS 13.4, *) {
            data = try fileHandle.read(upToCount: expectedBytesCount)
        } else {
            data = fileHandle.readData(ofLength: expectedBytesCount)
        }
        XCTAssertEqual(data?.count, expectedBytesCount)
    }

    func testWriteAndClose() throws {
        let fileManager = FileManager.default
        let temporaryDirectoryURL: URL
        if #available(macOS 10.12, *, iOS 10, *) {
            temporaryDirectoryURL = fileManager.temporaryDirectory
        } else {
            temporaryDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory())
        }
        let itemReplacementURL = try fileManager.url(for: .itemReplacementDirectory,
                                                     in: .userDomainMask,
                                                     appropriateFor: temporaryDirectoryURL,
                                                     create: true)
        addTeardownBlock {
            do {
                try fileManager.removeItem(at: itemReplacementURL)
            } catch let error {
                XCTFail(String(describing: error))
            }
        }
        let temporaryFileURL = itemReplacementURL.appendingPathComponent(ProcessInfo().globallyUniqueString)
        try httpGetRequestMessage.write(to: temporaryFileURL)
        let connection = try HTTPConnection(httpVersion: httpVersion, nativeHandle: writerFileDescriptor)
        let fileHandle = FileHandle(fileDescriptor: readerFileDescriptor)
        expectation(forNotification: .NSFileHandleReadToEndOfFileCompletion, object: fileHandle) { notification in
            let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data
            XCTAssertEqual(data, httpGetRequestMessage)
            return true
        }
        try connection.writeAndClose(contentsOf: temporaryFileURL)
        fileHandle.readToEndOfFileInBackgroundAndNotify()
        waitForExpectations(timeout: 0.5)
    }

    @objc private func writeData(into connection: AnyObject) {
        let connection = connection as! HTTPConnection
        connection.write(data: httpGetRequestMessage)
    }
}

private class HTTPConnectionDelegateHandler: HTTPConnectionDelegate {
    var didReceiveRequest: ((HTTPConnection, HTTPRequestMessage) -> Void)?
    var willClose: ((HTTPConnection) -> Void)?
    var didFailToHandleRequest: ((HTTPConnection, HTTPRequestMessage, Error) -> Void)?

    func httpConnection(_ connection: HTTPConnection, didReceive request: HTTPRequestMessage) {
        didReceiveRequest?(connection, request)
    }

    func httpConnectionWillClose(_ connection: HTTPConnection) {
        willClose?(connection)
    }

    func httpConnection(_ connection: HTTPConnection, didFailToHandle request: HTTPRequestMessage, error: Error) {
        didFailToHandleRequest?(connection, request, error)
    }
}

private let httpGetRequestMessage = """
GET / HTTP/1.1
Host: localhost

""".data(using: .utf8)!
