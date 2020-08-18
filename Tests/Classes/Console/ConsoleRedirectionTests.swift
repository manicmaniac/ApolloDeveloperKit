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
    private let previousConsoleRedirection = ConsoleRedirection.shared
    private var notificationCenter: NotificationCenter!
    private var delegateHandler: ConsoleRedirectionDelegateHandler!
    private var mockDuplicator: MockFileDescriptorDuplicator!

    override func setUp() {
        notificationCenter = NotificationCenter()
        delegateHandler = ConsoleRedirectionDelegateHandler()
        mockDuplicator = MockFileDescriptorDuplicator()
        let consoleRedirection = ConsoleRedirection(notificationCenter: notificationCenter, queue: .main, duplicator: mockDuplicator)
        ConsoleRedirection.setShared(consoleRedirection)
    }

    override func tearDown() {
        ConsoleRedirection.setShared(previousConsoleRedirection)
    }

    func testInit() {
        let consoleRedirection = ConsoleRedirection.shared
        consoleRedirection.addObserver(delegateHandler!, selector: #selector(delegateHandler.didReceiveConsoleDidWriteNotification(_:)))
        XCTAssertEqual(mockDuplicator.dupInvocationHistory, [1, 2])
        guard mockDuplicator.dup2InvocationHistory.count == 2 else {
            return XCTFail("dup2 must be called exactly twice but called \(mockDuplicator.dup2InvocationHistory.count) times.")
        }
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[0].fildes2, 1)
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[1].fildes2, 2)
        consoleRedirection.removeObserver(delegateHandler!)
    }

    func testDeinit() {
        let consoleRedirection = ConsoleRedirection.shared
        consoleRedirection.addObserver(delegateHandler!, selector: #selector(delegateHandler.didReceiveConsoleDidWriteNotification(_:)))
        mockDuplicator.clearInvocationHistory()
        consoleRedirection.removeObserver(delegateHandler!)
        guard mockDuplicator.dup2InvocationHistory.count == 2 else {
            return XCTFail("dup2 must be called exactly twice but called \(mockDuplicator.dup2InvocationHistory.count) times.")
        }
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[0].fildes2, 1)
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[1].fildes2, 2)
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

private class MockFileDescriptorDuplicator: FileDescriptorDuplicator {
    private(set) var dupInvocationHistory = [Int32]()
    private(set) var dup2InvocationHistory = [(fildes: Int32, fildes2: Int32)]()

    func dup(_ fildes: Int32) -> Int32 {
        dupInvocationHistory.append(fildes)
        return fildes
    }

    func dup2(_ fildes: Int32, _ fildes2: Int32) -> Int32 {
        dup2InvocationHistory.append((fildes, fildes2))
        return fildes2
    }

    func clearInvocationHistory() {
        dupInvocationHistory.removeAll()
        dup2InvocationHistory.removeAll()
    }
}
