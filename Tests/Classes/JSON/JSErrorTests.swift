//
//  JSErrorTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class JSErrorTests: XCTestCase {
    func testJSONValue() {
        let error = URLError(.badURL)
        let jsError = JSError(error)
        let dictionary = jsError.jsonValue as? [String: NSObject]
        XCTAssertNotNil(dictionary)
        XCTAssertEqual(dictionary?["message"], error.localizedDescription as NSString)
        XCTAssertNotNil(dictionary?["fileName"])
        XCTAssertNotNil(dictionary?["lineNumber"] as? Int)
    }
}
