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
        XCTAssertEqual(HTTPServerError.socketCreationFailed.errorCode, 100)
        XCTAssertEqual(HTTPServerError.socketSetOptionFailed.errorCode, 101)
        XCTAssertEqual(HTTPServerError.socketSetAddressFailed.errorCode, 102)
        XCTAssertEqual(HTTPServerError.socketSetAddressTimeout.errorCode, 103)
        XCTAssertEqual(HTTPServerError.socketListenFailed.errorCode, 104)
    }

    func testLocalizedDescription() {
        let defaultLocalizedDescriptionPrefix = "The operation"
        XCTAssertFalse(HTTPServerError.socketCreationFailed.localizedDescription.hasPrefix(defaultLocalizedDescriptionPrefix))
        XCTAssertFalse(HTTPServerError.socketSetOptionFailed.localizedDescription.hasPrefix(defaultLocalizedDescriptionPrefix))
        XCTAssertFalse(HTTPServerError.socketSetAddressFailed.localizedDescription.hasPrefix(defaultLocalizedDescriptionPrefix))
        XCTAssertFalse(HTTPServerError.socketSetAddressTimeout.localizedDescription.hasPrefix(defaultLocalizedDescriptionPrefix))
        XCTAssertFalse(HTTPServerError.socketListenFailed.localizedDescription.hasPrefix(defaultLocalizedDescriptionPrefix))
    }
}
