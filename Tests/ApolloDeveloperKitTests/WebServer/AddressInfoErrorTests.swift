//
//  AddressInfoErrorTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 10/2/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class AddressInfoErrorTests: XCTestCase {
    func testInit_withInvalidValue() throws {
        XCTAssertNil(AddressInfoErrorCode(rawValue: 0))
        XCTAssertNotNil(AddressInfoErrorCode(rawValue: 1))
        XCTAssertNotNil(AddressInfoErrorCode(rawValue: EAI_MAX - 1))
        XCTAssertNil(AddressInfoErrorCode(rawValue: EAI_MAX))
    }

    func testCode() throws {
        let code = try XCTUnwrap(AddressInfoErrorCode(rawValue: EAI_NODATA))
        let error = AddressInfoError(code)
        XCTAssertEqual(error.code.rawValue, code.rawValue)
    }

    func testLocalizedDescription() throws {
        let code = try XCTUnwrap(AddressInfoErrorCode(rawValue: EAI_NODATA))
        let error = AddressInfoError(code)
        XCTAssertEqual(error.localizedDescription, "No address associated with nodename")
    }
}
