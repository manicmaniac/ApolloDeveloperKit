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
    func testJSONValue() {
        let reference = Reference(key: "foo")
        guard let object = reference.jsonValue as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(object["generated"] as? Bool, true)
        XCTAssertEqual(object["id"] as? String, "foo")
        XCTAssertEqual(object["type"] as? String, "id")
    }
}
