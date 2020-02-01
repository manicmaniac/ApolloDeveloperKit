//
//  HTTPServerErrorTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 7/13/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class HTTPServerErrorTests: XCTestCase {

    func testErrorDomain() {
        XCTAssertEqual(HTTPServerError.errorDomain, "HTTPServerErrorDomain")
    }

    func testErrorCode() {
        XCTAssertEqual(HTTPServerError.multipleSocketErrorOccurred([:]).errorCode, 199)
    }

    func testLocalizedDescription() {
        XCTAssertTrue(HTTPServerError.multipleSocketErrorOccurred([:]).localizedDescription.contains("Multiple"))
    }
}
