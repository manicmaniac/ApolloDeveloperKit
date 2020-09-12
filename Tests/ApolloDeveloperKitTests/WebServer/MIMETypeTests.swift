//
//  MIMETypeTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 11/1/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class MIMETypeTests: XCTestCase {
    func testInitWithPathExtensionEncoding_withHTML() {
        let mimeType = MIMEType(pathExtension: "html", encoding: .utf8)
        guard case MIMEType.html(let encoding) = mimeType else {
            return XCTFail()
        }
        XCTAssertEqual(encoding, .utf8)
    }

    func testInitWithPathExtensionEncoding_withJavaScript() {
        let mimeType = MIMEType(pathExtension: "js", encoding: nil)
        guard case MIMEType.javascript = mimeType else {
            return XCTFail()
        }
    }

    func testInitWithPathExtensionEncoding_withJSON() {
        let mimeType = MIMEType(pathExtension: "json", encoding: nil)
        guard case MIMEType.json = mimeType else {
            return XCTFail()
        }
    }

    func testInitWithPathExtensionEncoding_withCSS() {
        let mimeType = MIMEType(pathExtension: "css", encoding: nil)
        guard case MIMEType.css = mimeType else {
            return XCTFail()
        }
    }

    func testInitWithPathExtensionEncoding_withPlainText() {
        let mimeType = MIMEType(pathExtension: "txt", encoding: .utf8)
        guard case MIMEType.plainText(let encoding) = mimeType else {
            return XCTFail()
        }
        XCTAssertEqual(encoding, .utf8)
    }

    func testInitWithPathExtensionEncoding_withPNG() {
        let mimeType = MIMEType(pathExtension: "png", encoding: nil)
        guard case MIMEType.png = mimeType else {
            return XCTFail()
        }
    }

    func testInitWithPathExtensionEncoding_withUnknownFileExtension() {
        let mimeType = MIMEType(pathExtension: "zip", encoding: nil)
        guard case MIMEType.octetStream = mimeType else {
            return XCTFail()
        }
    }

    func testDescription_withHTML() {
        XCTAssertEqual(String(describing: MIMEType.html(nil)), "text/html")
    }

    func testDescription_withHTMLSpecifyingCharacterSet() {
        XCTAssertEqual(String(describing: MIMEType.html(.utf8)), "text/html; charset=utf-8")
    }

    func testDescription_withJavaScript() {
        XCTAssertEqual(String(describing: MIMEType.javascript), "application/javascript")
    }

    func testDescription_withJSON() {
        XCTAssertEqual(String(describing: MIMEType.json), "application/json")
    }

    func testDescription_withCSS() {
        XCTAssertEqual(String(describing: MIMEType.css), "text/css")
    }

    func testDescription_withPlainText() {
        XCTAssertEqual(String(describing: MIMEType.plainText(nil)), "text/plain")
    }

    func testDescription_withPlainTextSpecifyingCharacterSet() {
        XCTAssertEqual(String(describing: MIMEType.plainText(.utf8)), "text/plain; charset=utf-8")
    }

    func testDescription_withPNG() {
        XCTAssertEqual(String(describing: MIMEType.png), "image/png")
    }

    func testDescription_withEventStream() {
        XCTAssertEqual(String(describing: MIMEType.eventStream), "text/event-stream")
    }

    func testDescription_withOctetStream() {
        XCTAssertEqual(String(describing: MIMEType.octetStream), "application/octet-stream")
    }
}
