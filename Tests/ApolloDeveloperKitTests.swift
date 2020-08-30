//
//  ApolloDeveloperKitTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/31/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
import ApolloDeveloperKit

class ApolloDeveloperKitTests: XCTestCase {
    func testApolloDeveloperKitVersionNumber() {
        let version = Bundle(identifier: "com.github.manicmaniac.ApolloDeveloperKit")!.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
        XCTAssertEqual(ApolloDeveloperKitVersionNumber, Double(version))
        XCTAssertGreaterThan(ApolloDeveloperKitVersionNumber, 0)
    }
}
