//
//  GraphQLRequestTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class GraphQLRequestTests: XCTestCase {
    func testInitWithJSONObject_withValidJSONObject() throws {
        let jsonObject: JSONObject = [
            "variables": [
                "input": [
                    "string": "foo" as NSString,
                    "integer": 42 as NSNumber,
                    "float": 4.2 as NSNumber,
                    "boolean": true as CFBoolean,
                    "array": ["foo"] as NSArray,
                    "null": NSNull()
                ]
            ],
            "operationName": NSNull(),
            "query": "query { posts { id } }"
        ]
        let request = try GraphQLRequest(jsonObject: jsonObject)
        XCTAssertNil(request.operationIdentifier)
        XCTAssertEqual(request.operationType, .query)
        XCTAssertEqual(request.operationDefinition, "query { posts { id } }")
        XCTAssertEqual(request.variables?.count, 1)
        guard let input = request.variables?["input"] as? [String: Any] else{
            return XCTFail()
        }
        XCTAssertEqual(input["string"] as? String, "foo")
        XCTAssertEqual(input["integer"] as? Int, 42)
        XCTAssertEqual(input["float"] as? Double, 4.2)
        XCTAssertEqual(input["boolean"] as? Bool, true)
        XCTAssertEqual(input["array"] as? [String], ["foo"])
    }

    func testInitWithJSONObject_withInvalidJSONObject() {
        let invalidJSONObject: JSONObject = [
            "operationName": Set<String>()
        ]
        XCTAssertThrowsError(try GraphQLRequest(jsonObject: invalidJSONObject)) { error in
            guard case JSONDecodingError.couldNotConvert(value: let jsonObject, to: let type) = error else {
                return XCTFail()
            }
            XCTAssertEqual(jsonObject as? NSDictionary, invalidJSONObject as NSDictionary)
            XCTAssert(type is GraphQLRequest.Type)
        }
    }
}
