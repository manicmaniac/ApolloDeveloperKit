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
        let record = Record(key: "key", [
            "String": "foo",
            "Int": 42,
            "Bool": true,
            "nil": nil as String? as Any,
            "NSString": "foo" as NSString,
            "NSNumber-Int": 42 as NSNumber,
            "NSNumber-Bool": true as NSNumber,
            "NSNull": NSNull(),
            "CFString": "foo" as CFString,
            "CFNumber-Int": 42 as CFNumber,
            "CFNumber-Bool": true as CFNumber
        ])
        guard let object = record.jsonValue as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(object["String"] as? String, "foo")
        XCTAssertEqual(object["Int"] as? Int, 42)
        XCTAssertEqual(object["Bool"] as? Bool, true)
        XCTAssertEqual(object["nil"] as? NSNull, NSNull())
        XCTAssertEqual(object["NSString"] as? String, "foo")
        XCTAssertEqual(object["NSNumber-Int"] as? Int, 42)
        XCTAssertEqual(object["NSNumber-Bool"] as? Bool, true)
        XCTAssertEqual(object["NSNull"] as? NSNull, NSNull())
        XCTAssertEqual(object["CFString"] as? String, "foo")
        XCTAssertEqual(object["CFNumber-Int"] as? Int, 42)
        XCTAssertEqual(object["CFNumber-Bool"] as? Bool, true)
    }
}
