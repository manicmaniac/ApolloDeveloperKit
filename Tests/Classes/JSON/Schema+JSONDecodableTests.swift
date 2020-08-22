//
//  Schema+JSONDecodableTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/22/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
import Apollo
@testable import ApolloDeveloperKit

class Schema_JSONDecodableTests: XCTestCase {
    func testOperationInitWithJSONObject_withInvalidJSONObject() {
        let invalidJSONObject: JSONObject = [
            "operationName": Set<String>()
        ]
        XCTAssertThrowsError(try Operation(jsonValue: invalidJSONObject)) { error in
            guard case JSONDecodingError.couldNotConvert(value: let jsonObject, to: let type) = error else {
                return XCTFail()
            }
            XCTAssertEqual(jsonObject as? NSDictionary, invalidJSONObject as NSDictionary)
            XCTAssert(type is ApolloDeveloperKit.Operation.Type)
        }
    }
}
