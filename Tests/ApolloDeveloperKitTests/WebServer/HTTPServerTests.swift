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
    private static let server = HTTPServer()
    private static let mockHTTPServerDelegate = MockHTTPServerDelegate()
    private static var port = UInt16(0)
    private var session: URLSession!

    override class func setUp() {
        server.delegate = mockHTTPServerDelegate
        port = try! server.start(randomPortIn: 49152...65535) // macOS ephemeral ports
    }

    override class func tearDown() {
        server.stop()
    }

    override func setUp() {
        session = URLSession(configuration: .test)
    }

    override func tearDown() {
        session.invalidateAndCancel()
    }

    func testIsRunning() {
        XCTAssertTrue(type(of: self).server.isRunning)
    }

    func testServerURL() {
        let serverURL = type(of: self).server.serverURL
        XCTAssertNotNil(serverURL)
        if let serverURL = serverURL {
            let regularExpression = try! NSRegularExpression(pattern: "http://\\d+\\.\\d+\\.\\d+\\.\\d+:\(type(of: self).port)", options: [])
            let range = NSRange(location: 0, length: serverURL.absoluteString.count)
            let matches = regularExpression.matches(in: serverURL.absoluteString, options: [], range: range)
            XCTAssertFalse(matches.isEmpty)
        }
    }

    func testGetRequest() {
        let expectation = self.expectation(description: "receive response")
        let url = URL(string: "http://127.0.0.1:\(type(of: self).port)")!
        let task = session.dataTask(with: url) { data, response, error in
            let response = response as? HTTPURLResponse
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertNil(error)
            let headerFields = response?.allHeaderFields as? [String: String]
            XCTAssertEqual(headerFields?["Content-Type"], "text/plain; charset=utf-8")
            XCTAssertEqual(headerFields?["X-Request-Method"], "GET")
            XCTAssertEqual(headerFields?["X-Request-Url"], url.absoluteString + "/")
            XCTAssertEqual(data?.count, 0)
            expectation.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testPostRequestWithContentLength() {
        let expectation = self.expectation(description: "receive response")
        let url = URL(string: "http://127.0.0.1:\(type(of: self).port)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "foo".data(using: .utf8)!
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        request.setValue("close", forHTTPHeaderField: "Connection")
        let task = session.dataTask(with: request) { data, response, error in
            let response = response as? HTTPURLResponse
            XCTAssertEqual(response?.statusCode, 200)
            XCTAssertNil(error)
            let headerFields = response?.allHeaderFields as? [String: String]
            XCTAssertEqual(headerFields?["Content-Type"], "text/plain; charset=utf-8")
            XCTAssertEqual(headerFields?["Content-Length"], "3")
            XCTAssertEqual(headerFields?["X-Request-Method"], "POST")
            XCTAssertEqual(headerFields?["X-Request-Url"], url.absoluteString + "/")
            let bodyString = data.flatMap { data in String(data: data, encoding: .utf8) }
            XCTAssertEqual(bodyString, "foo")
            expectation.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 0.25, handler: nil)
    }
}

class MockHTTPServerDelegate: HTTPServerDelegate {
    func server(_ server: HTTPServer, didStartListeningTo port: UInt16) {
    }

    func server(_ server: HTTPServer, didReceiveRequest request: URLRequest, connection: HTTPConnection) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: connection.httpVersion, headerFields: [
            "Content-Length": String(request.httpBody?.count ?? 0),
            "Content-Type": "text/plain; charset=utf-8",
            "X-Request-Method": request.httpMethod!,
            "X-Request-Url": request.url!.absoluteString
        ])!
        connection.write(response: response, body: request.httpBody)
        connection.close()
    }
}
