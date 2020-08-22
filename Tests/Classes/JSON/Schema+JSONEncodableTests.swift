//
//  Schema+JSONEncodableTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/22/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class Schema_JSONEncodableTests: XCTestCase {
    func testErrorLikeInitWithJSONValue() {
        let error = URLError(.badURL)
        let errorLike = ErrorLike(error: error)
        XCTAssertEqual(errorLike.message, error.localizedDescription)
        XCTAssertEqual(errorLike.name, "NSError")
        XCTAssertNil(errorLike.fileName)
        XCTAssertNil(errorLike.lineNumber)
        XCTAssertNil(errorLike.columnNumber)
    }
}
