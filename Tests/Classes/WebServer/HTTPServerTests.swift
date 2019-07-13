//
//  HTTPServerTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 7/1/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class HTTPServerTests: XCTestCase {
    private var server: HTTPServer!

    override func setUp() {
        server = HTTPServer()
        server.requestHandler = self
        try! server.start(port: 8085)
    }

    override func tearDown() {
        server.stop()
        CFRunLoopRunInMode(.defaultMode, 0.25, false)
    }

    func testIsRunning() {
        XCTAssertTrue(server.isRunning)
    }

    func testServerURL() {
        XCTAssertEqual(server.serverURL?.absoluteString, "http://127.0.0.1:8085/")
    }

    func testGetRequest() {
        let expectation = self.expectation(description: "receive response")
        let url = URL(string: "http://127.0.0.1:8085")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            let response = response as? HTTPURLResponse
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertNil(error)
            let headerFields = response?.allHeaderFields as? [String: String]
            XCTAssertEqual(headerFields?["Content-Type"], "text/plain; charset=utf-8")
            XCTAssertEqual(headerFields?["X-Request-Method"], "GET")
            XCTAssertEqual(headerFields?["X-Request-Url"], "/")
            XCTAssertEqual(data?.count, 0)
            expectation.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testPostRequestWithContentLength() {
        let expectation = self.expectation(description: "receive response")
        let url = URL(string: "http://127.0.0.1:8085")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "foo".data(using: .utf8)!
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.setValue("close", forHTTPHeaderField: "Connection")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            let response = response as? HTTPURLResponse
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertNil(error)
            let headerFields = response?.allHeaderFields as? [String: String]
            XCTAssertEqual(headerFields?["Content-Type"], "text/plain; charset=utf-8")
            XCTAssertEqual(headerFields?["Content-Length"], "3")
            XCTAssertEqual(headerFields?["X-Request-Method"], "POST")
            XCTAssertEqual(headerFields?["X-Request-Url"], "/")
            let bodyString = data.flatMap { data in String(data: data, encoding: .utf8) }
            XCTAssertEqual(bodyString, "foo")
            expectation.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 0.25, handler: nil)
    }
}

extension HTTPServerTests: HTTPRequestHandler {
    func server(_ server: HTTPServer, didReceiveRequest request: CFHTTPMessage, fileHandle: FileHandle, completion: @escaping () -> Void) {
        let url = CFHTTPMessageCopyRequestURL(request)!.takeRetainedValue()
        let method = CFHTTPMessageCopyRequestMethod(request)!.takeRetainedValue()
        let body = CFHTTPMessageCopyBody(request)?.takeRetainedValue()
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, nil, kCFHTTPVersion1_1).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "text/plain; charset=utf-8" as CFString)
        CFHTTPMessageSetHeaderFieldValue(response, "X-Request-Method" as CFString, method)
        CFHTTPMessageSetHeaderFieldValue(response, "X-Request-Url" as CFString, CFURLGetString(url))
        if let body = body {
            CFHTTPMessageSetHeaderFieldValue(response, "Content-Length" as CFString, String(CFDataGetLength(body)) as CFString)
            CFHTTPMessageSetBody(response, body)
        }
        let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
        fileHandle.write(data)
        completion()
    }
}
