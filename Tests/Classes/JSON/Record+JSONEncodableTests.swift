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
    func testJSONValue_whenValueIsSwiftStandardType() {
        let record = Record(key: "key", [
            "String": "foo",
            "Int": 42,
            "Double": 1.5,
            "Bool": true,
            "nil": nil as String? as Any,
            "[String]": ["foo", "bar"],
            "[[Int]]": [[0, 42]],
            "[String: String]": ["foo": "bar"]
        ])
        guard let object = record.jsonValue as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(object["String"] as? String, "foo")
        XCTAssertEqual(object["Int"] as? Int, 42)
        XCTAssertEqual(object["Double"] as? Double, 1.5)
        XCTAssertEqual(object["Bool"] as? Bool, true)
        XCTAssertEqual(object["nil"] as? NSNull, NSNull())
        XCTAssertEqual(object["[String]"] as? [String], ["foo", "bar"])
        XCTAssertEqual(object["[[Int]]"] as? [[Int]], [[0, 42]])
        XCTAssertEqual(object["[String: String]"] as? [String: String], ["foo": "bar"])
    }

    func testJSONValue_whenValueIsFoundationClass() {
        let record = Record(key: "key", [
            "NSString": "foo" as NSString,
            "NSNumber-Int": 42 as NSNumber,
            "NSNumber-Double": 1.5 as NSNumber,
            "NSNumber-Bool": true as NSNumber,
            "NSNull": NSNull(),
            "NSArray<NSString>": ["foo" as NSString, "bar" as NSString] as NSArray,
            "NSArray<NSArray<NSNumber>>": [[0 as NSNumber, 42 as NSNumber] as NSArray] as NSArray,
            "NSDictionary<NSString, NSString>": ["foo" as NSString: "bar" as NSString] as NSDictionary
        ])
        guard let object = record.jsonValue as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(object["NSString"] as? NSString, "foo")
        XCTAssertEqual(object["NSNumber-Int"] as? NSNumber, 42)
        XCTAssertEqual(object["NSNumber-Double"] as? NSNumber, 1.5)
        XCTAssertEqual(object["NSNumber-Bool"] as? NSNumber, true)
        XCTAssertEqual(object["NSNull"] as? NSNull, NSNull())
        XCTAssertEqual(object["NSArray<NSString>"] as? NSArray, ["foo", "bar"])
        XCTAssertEqual(object["NSArray<NSArray<NSNumber>>"] as? NSArray, [[0, 42]])
        XCTAssertEqual(object["NSDictionary<NSString, NSString>"] as? [String: String], ["foo": "bar"])
    }

    func testJSONValue_whenValueIsCoreFoundationClass() {
        let record = Record(key: "key", [
            "CFString": "foo" as CFString,
            "CFNumber-Int": 42 as CFNumber,
            "CFNumber-Double": 1.5 as CFNumber,
            "CFBoolean": true as CFBoolean,
            "CFNull": kCFNull!,
            "CFArray<CFString>": ["foo" as CFString, "bar" as CFString] as CFArray,
            "CFArray<CFArray<CFNumber>>": [[0 as CFNumber, 42 as CFNumber] as CFArray] as CFArray,
            "CFDictionary<CFString, CFString>": ["foo" as CFString: "bar" as CFString] as CFDictionary
        ])
        guard let object = record.jsonValue as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(object["CFString"] as! CFString, "foo" as CFString)
        XCTAssertEqual(object["CFNumber-Int"] as! CFNumber, 42 as CFNumber)
        XCTAssertEqual(object["CFNumber-Double"] as! CFNumber, 1.5 as CFNumber)
        XCTAssertEqual(object["CFBoolean"] as! CFBoolean, true as CFBoolean)
        XCTAssertEqual(object["CFNull"] as! CFNull, kCFNull!)
        XCTAssertEqual(object["CFArray<CFString>"] as! CFArray, ["foo" as CFString, "bar" as CFString] as CFArray)
        XCTAssertEqual(object["CFArray<CFArray<CFNumber>>"] as! CFArray, [[0 as CFNumber, 42 as CFNumber] as CFArray] as CFArray)
        XCTAssertEqual(object["CFDictionary<CFString, CFString>"] as! CFDictionary, ["foo" as CFString: "bar" as CFString] as CFDictionary)
    }

    func testJSONValue_whenValueIsHybridType() {
        let record = Record(key: "key", [
            "[NSString]": ["foo" as NSString, "bar" as NSString],
            "[NSString: Int]": ["foo" as NSString: 42]
        ])
        guard let object = record.jsonValue as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(object["[NSString]"] as? [NSString], ["foo", "bar"])
        XCTAssertEqual(object["[NSString: Int]"] as? [NSString: Int], ["foo": 42])
    }
}
