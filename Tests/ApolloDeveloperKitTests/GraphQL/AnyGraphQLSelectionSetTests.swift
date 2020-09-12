//
//  AnyGraphQLSelectionSetTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class AnyGraphQLSelectionSetTests: XCTestCase {
    func testSelections() {
        XCTAssertTrue(AnyGraphQLSelectionSet.selections.isEmpty)
    }

    func testInitWithUnsafeResultMap() {
        let resultMap = ["foo": "bar"]
        let selectionSet = AnyGraphQLSelectionSet(unsafeResultMap: resultMap)
        XCTAssertEqual(selectionSet.resultMap as? [String: String], resultMap)
    }
}
