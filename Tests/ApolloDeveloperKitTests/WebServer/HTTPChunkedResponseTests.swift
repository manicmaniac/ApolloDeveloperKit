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
        XCTAssertEqual(chunk.data, "0\r\n\r\n".data(using: .utf8)!)
    }

    func testData_withNonemptyData() {
        let chunk = HTTPChunkedResponse(rawData: "data: foo\n\n".data(using: .utf8)!)
        XCTAssertEqual(chunk.data, "b\r\ndata: foo\n\n\r\n".data(using: .utf8)!)
    }
}
