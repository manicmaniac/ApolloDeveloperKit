//
//  MimeTypeTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 11/1/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class MimeTypeTests: XCTestCase {
    func testInitWithPathExtensionEncoding_withHTML() {
        let mimeType = MimeType(pathExtension: "html", encoding: .utf8)
        guard case MimeType.html(let encoding) = mimeType else {
            return XCTFail()
        }
        XCTAssertEqual(encoding, .utf8)
    }

    func testInitWithPathExtensionEncoding_withJavaScript() {
        let mimeType = MimeType(pathExtension: "js", encoding: nil)
        guard case MimeType.javascript = mimeType else {
            return XCTFail()
        }
    }

    func testInitWithPathExtensionEncoding_withJSON() {
        let mimeType = MimeType(pathExtension: "json", encoding: nil)
        guard case MimeType.json = mimeType else {
            return XCTFail()
        }
    }

    func testInitWithPathExtensionEncoding_withCSS() {
        let mimeType = MimeType(pathExtension: "css", encoding: nil)
        guard case MimeType.css = mimeType else {
            return XCTFail()
        }
    }

    func testInitWithPathExtensionEncoding_withPlainText() {
        let mimeType = MimeType(pathExtension: "txt", encoding: .utf8)
        guard case MimeType.plainText(let encoding) = mimeType else {
            return XCTFail()
        }
        XCTAssertEqual(encoding, .utf8)
    }

    func testInitWithPathExtensionEncoding_withPNG() {
        let mimeType = MimeType(pathExtension: "png", encoding: nil)
        guard case MimeType.png = mimeType else {
            return XCTFail()
        }
    }

    func testInitWithPathExtensionEncoding_withUnknownFileExtension() {
        let mimeType = MimeType(pathExtension: "zip", encoding: nil)
        guard case MimeType.octetStream = mimeType else {
            return XCTFail()
        }
    }

    func testDescription_withHTML() {
        XCTAssertEqual(String(describing: MimeType.html(nil)), "text/html")
    }

    func testDescription_withHTMLSpecifyingCharacterSet() {
        XCTAssertEqual(String(describing: MimeType.html(.utf8)), "text/html; charset=utf-8")
    }

    func testDescription_withJavaScript() {
        XCTAssertEqual(String(describing: MimeType.javascript), "application/javascript")
    }

    func testDescription_withJSON() {
        XCTAssertEqual(String(describing: MimeType.json), "application/json")
    }

    func testDescription_withCSS() {
        XCTAssertEqual(String(describing: MimeType.css), "text/css")
    }

    func testDescription_withPlainText() {
        XCTAssertEqual(String(describing: MimeType.plainText(nil)), "text/plain")
    }

    func testDescription_withPlainTextSpecifyingCharacterSet() {
        XCTAssertEqual(String(describing: MimeType.plainText(.utf8)), "text/plain; charset=utf-8")
    }

    func testDescription_withPNG() {
        XCTAssertEqual(String(describing: MimeType.png), "image/png")
    }

    func testDescription_withEventStream() {
        XCTAssertEqual(String(describing: MimeType.eventStream), "text/event-stream")
    }

    func testDescription_withOctetStream() {
        XCTAssertEqual(String(describing: MimeType.octetStream), "application/octet-stream")
    }
}
