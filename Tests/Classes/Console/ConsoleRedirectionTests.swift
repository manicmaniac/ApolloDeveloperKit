//
//  ConsoleRedirectionTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 11/5/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class ConsoleRedirectionTests: XCTestCase {
    private var notificationCenter: NotificationCenter!
    private var delegateHandler: ConsoleRedirectionDelegateHandler!
    private var mockDuplicator: MockFileDescriptorDuplicator!
    private var temporaryDirectoryURL: URL!
    private var standardOutputFileHandle: FileHandle!
    private var standardErrorFileHandle: FileHandle!

    override func setUpWithError() throws {
        notificationCenter = NotificationCenter()
        delegateHandler = ConsoleRedirectionDelegateHandler()
        mockDuplicator = MockFileDescriptorDuplicator()
        let fileManager = FileManager.default
        temporaryDirectoryURL = try fileManager.url(for: .itemReplacementDirectory,
                                                    in: .userDomainMask,
                                                    appropriateFor: URL(fileURLWithPath: NSTemporaryDirectory()),
                                                    create: true)
        let standardOutputURL = temporaryDirectoryURL.appendingPathComponent("stdout")
        fileManager.createFile(atPath: standardOutputURL.path, contents: nil)
        standardOutputFileHandle = try FileHandle(forWritingTo: standardOutputURL)
        let standardErrorURL = temporaryDirectoryURL.appendingPathComponent("stderr")
        fileManager.createFile(atPath: standardErrorURL.path, contents: nil)
        standardErrorFileHandle = try FileHandle(forWritingTo: standardErrorURL)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: temporaryDirectoryURL)
    }

    func testInit() {
        let consoleRedirection = ConsoleRedirection(standardOutputFileDescriptor: stdout,
                                                    standardErrorFileDescriptor: stderr,
                                                    notificationCenter: notificationCenter,
                                                    queue: .main,
                                                    duplicator: mockDuplicator)
        consoleRedirection.addObserver(delegateHandler!, selector: #selector(delegateHandler.didReceiveConsoleDidWriteNotification(_:)))
        XCTAssertEqual(mockDuplicator.dupInvocationHistory, [stdout, stderr])
        guard mockDuplicator.dup2InvocationHistory.count == 2 else {
            return XCTFail("dup2 must be called exactly twice but called \(mockDuplicator.dup2InvocationHistory.count) times.")
        }
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[0].fildes2, stdout)
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[1].fildes2, stderr)
        consoleRedirection.removeObserver(delegateHandler!)
    }

    func testDeinit() {
        let consoleRedirection = ConsoleRedirection(standardOutputFileDescriptor: stdout,
                                                    standardErrorFileDescriptor: stderr,
                                                    notificationCenter: notificationCenter,
                                                    queue: .main,
                                                    duplicator: mockDuplicator)
        consoleRedirection.addObserver(delegateHandler!, selector: #selector(delegateHandler.didReceiveConsoleDidWriteNotification(_:)))
        mockDuplicator.clearInvocationHistory()
        consoleRedirection.removeObserver(delegateHandler!)
        guard mockDuplicator.dup2InvocationHistory.count == 2 else {
            return XCTFail("dup2 must be called exactly twice but called \(mockDuplicator.dup2InvocationHistory.count) times.")
        }
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[0].fildes2, stdout)
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[1].fildes2, stderr)
    }

    func testNotification_whenWritingToStandardOutput() throws {
        let consoleRedirection = ConsoleRedirection(standardOutputFileDescriptor: stdout,
                                                    standardErrorFileDescriptor: stderr,
                                                    notificationCenter: notificationCenter,
                                                    queue: .main,
                                                    duplicator: DarwinFileDescriptorDuplicator())
        consoleRedirection.addObserver(delegateHandler!, selector: #selector(delegateHandler.didReceiveConsoleDidWriteNotification(_:)))
        let data = Data("foo".utf8)
        let expectation = self.expectation(description: "Callback should be called.")
        delegateHandler.consoleDidWriteDataToDestinationCallback = { receivedConsoleRedirection, receivedData, receivedDestination in
            defer { expectation.fulfill() }
            XCTAssert(receivedConsoleRedirection === consoleRedirection)
            XCTAssertEqual(receivedData, data)
            XCTAssertEqual(receivedDestination, .standardOutput)
        }
        if #available(macOS 10.15.4, *, iOS 13.4, *) {
            try standardOutputFileHandle.write(contentsOf: data)
        } else {
            standardOutputFileHandle.write(data)
        }
        waitForExpectations(timeout: 0.25)
    }

    func testNotification_whenWritingToStandardError() throws {
        let consoleRedirection = ConsoleRedirection(standardOutputFileDescriptor: stdout,
                                                    standardErrorFileDescriptor: stderr,
                                                    notificationCenter: notificationCenter,
                                                    queue: .main,
                                                    duplicator: DarwinFileDescriptorDuplicator())
        consoleRedirection.addObserver(delegateHandler!, selector: #selector(delegateHandler.didReceiveConsoleDidWriteNotification(_:)))
        let data = Data("foo".utf8)
        let expectation = self.expectation(description: "Callback should be called.")
        delegateHandler.consoleDidWriteDataToDestinationCallback = { receivedConsoleRedirection, receivedData, receivedDestination in
            defer { expectation.fulfill() }
            XCTAssert(receivedConsoleRedirection === consoleRedirection)
            XCTAssertEqual(receivedData, data)
            XCTAssertEqual(receivedDestination, .standardError)
        }
        if #available(macOS 10.15.4, *, iOS 13.4, *) {
            try standardErrorFileHandle.write(contentsOf: data)
        } else {
            standardErrorFileHandle.write(data)
        }
        waitForExpectations(timeout: 0.25)
    }

    private var stdout: Int32 {
        return standardOutputFileHandle.fileDescriptor
    }

    private var stderr: Int32 {
        return standardErrorFileHandle.fileDescriptor
    }
}

private class ConsoleRedirectionDelegateHandler {
    var consoleDidWriteDataToDestinationCallback: ((ConsoleRedirection, Data, ConsoleRedirection.Destination) -> Void)?

    @objc func didReceiveConsoleDidWriteNotification(_ notification: Notification) {
        let console = notification.object as! ConsoleRedirection
        let data = notification.userInfo?["data"] as! Data
        let destination = notification.userInfo?["destination"] as! ConsoleRedirection.Destination
        consoleDidWriteDataToDestinationCallback?(console, data, destination)
    }
}
