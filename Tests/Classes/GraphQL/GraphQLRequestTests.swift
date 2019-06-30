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
    func testInitWithJSONValue() throws {
        let jsonValue: JSONObject = [
            "variables": ["foo": 0],
            "operationName": NSNull(),
            "query": "query { posts { id } }"
        ]
        let request = try GraphQLRequest(jsonValue: jsonValue)
        XCTAssertNil(request.operationIdentifier)
        XCTAssertEqual(request.operationType, .query)
        XCTAssertEqual(request.operationDefinition, "query { posts { id } }")
        XCTAssertEqual(request.variables?.count, 1)
        XCTAssertEqual(request.variables?["foo"] as? Int, 0)
    }
}
