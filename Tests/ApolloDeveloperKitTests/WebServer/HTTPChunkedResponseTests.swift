//
//  HTTPChunkedResponseTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 11/3/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class HTTPChunkedResponseTests: XCTestCase {
    func testData_withEmptyData() {
        let chunk = HTTPChunkedResponse(rawData: Data())
        XCTAssertEqual(chunk.data, Data("0\r\n\r\n".utf8))
    }

    func testData_withNonemptyData() {
        let chunk = HTTPChunkedResponse(rawData: Data("data: foo\n\n".utf8))
        XCTAssertEqual(chunk.data, Data("b\r\ndata: foo\n\n\r\n".utf8))
    }

    func testData_withEventStreamMessage() {
        let chunk = HTTPChunkedResponse(event: EventStreamMessage.ping)
        XCTAssertEqual(chunk.data, Data("3\r\n:\n\n\r\n".utf8))
    }
}
