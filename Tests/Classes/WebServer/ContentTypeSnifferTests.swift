//
//  ContentTypeSnifferTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 11/10/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class ContentTypeSnifferTests: XCTestCase {
    func testContentTypeForPathExtensionPreferredEncoding_withHTML() {
        let contentType = ContentTypeSniffer.shared.contentType(for: "html", preferredEncoding: .utf8)
        XCTAssertEqual(contentType, "text/html; charset=utf-8")
    }

    func testContentTypeForPathExtensionPreferredEncoding_withJS() {
        let contentType = ContentTypeSniffer.shared.contentType(for: "js", preferredEncoding: .utf8)
        XCTAssertEqual(contentType, "text/javascript; charset=utf-8")
    }

    func testContentTypeForPathExtensionPreferredEncoding_withCSS() {
        let contentType = ContentTypeSniffer.shared.contentType(for: "css", preferredEncoding: .utf8)
        XCTAssertEqual(contentType, "text/css; charset=utf-8")
    }

    func testContentTypeForPathExtensionPreferredEncoding_withPNG() {
        let contentType = ContentTypeSniffer.shared.contentType(for: "png", preferredEncoding: .utf8)
        XCTAssertEqual(contentType, "image/png")
    }
}
