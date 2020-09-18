//
//  Reference+JSONEncodableTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class Reference_JSONEncodableTests: XCTestCase {
    func testJSONValue() throws {
        let reference = Reference(key: "foo")
        let object = try XCTUnwrap(reference.jsonValue as? [String: Any])
        XCTAssertEqual(object["generated"] as? Bool, true)
        XCTAssertEqual(object["id"] as? String, "foo")
        XCTAssertEqual(object["type"] as? String, "id")
    }
}
