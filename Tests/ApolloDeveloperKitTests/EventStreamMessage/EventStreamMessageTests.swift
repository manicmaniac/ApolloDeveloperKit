//
//  EventStreamMessageTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/29/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class EventStreamMessageTests: XCTestCase {
    func testPing() {
        XCTAssertEqual(EventStreamMessage.ping.rawValue, ":\n\n")
    }

    func testInitWithRawValue_withEmptyString() {
        XCTAssertNil(EventStreamMessage(rawValue: ""))
    }

    func testInitWithRawValue_withValidString() {
        let rawValue = "event: foo\ndata: bar\n\n"
        XCTAssertEqual(EventStreamMessage(rawValue: rawValue)?.rawValue, rawValue)
    }

    func testInitWithEvent() {
        XCTAssertEqual(EventStreamMessage(event: "foo").rawValue, "event: foo\n\n")
    }

    func testInitWithData() {
        XCTAssertEqual(EventStreamMessage(data: "foo").rawValue, "data: foo\n\n")
    }

    func testInitWithData_withMultilineString() {
        let string = """
        foo
        bar
        baz
        """
        let expectedRawValue = """
        data: foo
        data: bar
        data: baz\n\n
        """
        XCTAssertEqual(EventStreamMessage(data: string).rawValue, expectedRawValue)
    }

    func testInitWithId() {
        XCTAssertEqual(EventStreamMessage(id: "foo").rawValue, "id: foo\n\n")
    }

    func testInitWithRetry() {
        XCTAssertEqual(EventStreamMessage(retry: 42).rawValue, "retry: 42\n\n")
    }

    func testInitWithEventDataIdRetry() {
        let message = EventStreamMessage(event: "foo",
                                         data: "bar",
                                         id: "baz",
                                         retry: 42)
        let expectedRawValue = """
        event: foo
        data: bar
        id: baz
        retry: 42\n\n
        """
        XCTAssertEqual(message.rawValue, expectedRawValue)
    }

    func testDescription() {
        let message = EventStreamMessage(event: "foo",
                                         data: "bar",
                                         id: "baz",
                                         retry: 42)
        let expectedDescription = """
        event: foo
        data: bar
        id: baz
        retry: 42\n\n
        """
        XCTAssertEqual(String(describing: message), expectedDescription)
    }

    func testInitWithDescription() {
        let description = "event: foo\ndata: bar\n\n"
        XCTAssertEqual(EventStreamMessage(description)?.rawValue, description)
    }

    func testMessage() {
        XCTAssertEqual(EventStreamMessage.ping.message, EventStreamMessage.ping)
    }

    func testHash() {
        let message1 = EventStreamMessage(event: "foo", data: "bar")
        let message2 = EventStreamMessage(event: "foo", data: "bar")
        let message3 = EventStreamMessage(event: "baz", data: "qux")
        XCTAssertEqual(message1.hashValue, message2.hashValue)
        XCTAssertNotEqual(message2.hashValue, message3.hashValue)
        // Somehow the above code doesn't invoke `hash(into:)` but the below does.
        let messageSet: Set<EventStreamMessage> = [message1, message2, message3]
        XCTAssertEqual(messageSet.count, 2)
    }
}
