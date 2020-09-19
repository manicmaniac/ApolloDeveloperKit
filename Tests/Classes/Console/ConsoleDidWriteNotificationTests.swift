//
//  ConsoleDidWriteNotificationTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/25/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class ConsoleDidWriteNotificationTests: XCTestCase {
    private var consoleRedirection: ConsoleRedirection!

    override func setUp() {
        let notificationCenter = NotificationCenter()
        let duplicator = MockFileDescriptorDuplicator()
        self.consoleRedirection = ConsoleRedirection(notificationCenter: notificationCenter, queue: .main, duplicator: duplicator)
    }

    func testInitWithObjectDataDestination() {
        let data = Data()
        let destination = ConsoleRedirection.Destination.standardOutput
        let notification = ConsoleDidWriteNotification(object: consoleRedirection, data: data, destination: destination)
        XCTAssert(notification.object === consoleRedirection)
        XCTAssertEqual(notification.data, data)
        XCTAssertEqual(notification.destination, destination)
    }

    func testInitWithRawValue() throws {
        let data = Data()
        let destination = ConsoleRedirection.Destination.standardOutput
        let rawValue = Notification(name: .consoleDidWrite, object: consoleRedirection, userInfo: [
            "data": data,
            "destination": destination
        ])
        let notification = try XCTUnwrap(ConsoleDidWriteNotification(rawValue: rawValue))
        XCTAssert(notification.object === consoleRedirection)
        XCTAssertEqual(notification.data, data)
        XCTAssertEqual(notification.destination, destination)
    }

    func testInitWithRawValue_withInvalidRawValue() {
        let rawValue = Notification(name: Notification.Name("invalid"))
        let notification = ConsoleDidWriteNotification(rawValue: rawValue)
        XCTAssertNil(notification)
    }
}
