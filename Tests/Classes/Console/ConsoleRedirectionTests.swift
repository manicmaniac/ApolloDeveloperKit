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

    override func setUp() {
        notificationCenter = NotificationCenter()
        delegateHandler = ConsoleRedirectionDelegateHandler()
        mockDuplicator = MockFileDescriptorDuplicator()
    }

    func testInit() {
        let consoleRedirection = ConsoleRedirection(notificationCenter: notificationCenter, queue: .main, duplicator: mockDuplicator)
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
        let consoleRedirection = ConsoleRedirection(notificationCenter: notificationCenter, queue: .main, duplicator: mockDuplicator)
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
