//
//  ApolloDeveloperKitTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 9/30/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class ApolloDeveloperKitSwiftTests: XCTestCase {
    func testVersionNumber() {
        XCTAssertEqual(ApolloDeveloperKitVersionNumber, 1.0)
    }
}
