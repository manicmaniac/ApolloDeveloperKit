//
//  KeyedStackTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/25/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class KeyedStackTests: XCTestCase {
    func testPush() {
        var stack = KeyedStack<String, Int>()
        stack.push(0, for: "foo")
        stack.push(1, for: "bar")
        stack.push(2, for: "foo")
        let elements = Array(stack)
        XCTAssertEqual(elements.count, 3)
        XCTAssertEqual(elements[0].0, "foo")
        XCTAssertEqual(elements[0].1, 0)
        XCTAssertEqual(elements[1].0, "bar")
        XCTAssertEqual(elements[1].1, 1)
        XCTAssertEqual(elements[2].0, "foo")
        XCTAssertEqual(elements[2].1, 2)
    }

    func testSubscriptGet_whenKeyExists() {
        var stack = KeyedStack<String, Int>()
        stack.push(0, for: "foo")
        XCTAssertEqual(stack["foo"], 0)
    }

    func testSubscriptGet_whenKeyDoesNotExist() {
        let stack = KeyedStack<String, Int>()
        XCTAssertNil(stack["foo"])
    }

    func testSubscriptGet_whenMultipleKeysExist() {
        var stack = KeyedStack<String, Int>()
        stack.push(0, for: "foo")
        stack.push(1, for: "foo")
        XCTAssertEqual(stack["foo"], 1)
    }

    func testSubscriptSet_whenKeyExists() {
        var stack = KeyedStack<String, Int>()
        stack.push(0, for: "foo")
        stack["foo"] = 1
        let elements = Array(stack)
        XCTAssertEqual(elements.count, 1)
        XCTAssertEqual(elements[0].0, "foo")
        XCTAssertEqual(elements[0].1, 1)
    }

    func testSubscriptSet_whenKeyDoesNotExist() {
        var stack = KeyedStack<String, Int>()
        stack.push(0, for: "foo")
        stack["bar"] = 1
        let elements = Array(stack)
        XCTAssertEqual(elements.count, 2)
        XCTAssertEqual(elements[0].0, "foo")
        XCTAssertEqual(elements[0].1, 0)
        XCTAssertEqual(elements[1].0, "bar")
        XCTAssertEqual(elements[1].1, 1)
    }

    func testSubscriptSet_whenMultipleKeysExist() {
        var stack = KeyedStack<String, Int>()
        stack.push(0, for: "foo")
        stack.push(1, for: "foo")
        stack["foo"] = 2
        let elements = Array(stack)
        XCTAssertEqual(elements.count, 2)
        XCTAssertEqual(elements[0].0, "foo")
        XCTAssertEqual(elements[0].1, 0)
        XCTAssertEqual(elements[1].0, "foo")
        XCTAssertEqual(elements[1].1, 2)
    }

    func testSubscriptSet_whenKeyExistsButValueIsNil() {
        var stack = KeyedStack<String, Int>()
        stack.push(0, for: "foo")
        stack["foo"] = nil
        let elements = Array(stack)
        XCTAssert(elements.isEmpty)
    }

    func testSubscriptSet_whenKeyDoesNotExistAndValueIsNil() {
        var stack = KeyedStack<String, Int>()
        stack.push(0, for: "foo")
        stack["bar"] = nil
        let elements = Array(stack)
        XCTAssertEqual(elements.count, 1)
        XCTAssertEqual(elements[0].0, "foo")
        XCTAssertEqual(elements[0].1, 0)
    }
}
