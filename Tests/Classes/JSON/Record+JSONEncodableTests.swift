//
//  Record+JSONEncodableTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class Record_JSONEncodableTests: XCTestCase {
    func testJSONValue() {
        let record = Record(key: "foo", [
            "bar": "baz",
            "qux": 42,
            "quux": true
        ])
        guard let object = record.jsonValue as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(object["bar"] as? String, "baz")
        XCTAssertEqual(object["qux"] as? Int, 42)
        XCTAssertEqual(object["quux"] as? Bool, true)
    }
}
