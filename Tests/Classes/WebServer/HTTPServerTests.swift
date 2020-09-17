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
    private var mockHTTPServerDelegate: MockHTTPServerDelegate!
    private var port = UInt16(0)
    private var session: URLSession!

    override func setUp() {
        server = HTTPServer()
        mockHTTPServerDelegate = MockHTTPServerDelegate()
        server.delegate = mockHTTPServerDelegate
        port = try! server.start(randomPortIn: 49152...65535) // macOS ephemeral ports
        session = URLSession(configuration: .test)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        server.stop()
    }

    func testIsRunning() {
        XCTAssertTrue(server.isRunning)
    }

    func testServerURL() {
        let serverURL = server.serverURL
        XCTAssertNotNil(serverURL)
        if let serverURL = serverURL {
            let regularExpression = try! NSRegularExpression(pattern: "http://\\d+\\.\\d+\\.\\d+\\.\\d+:\(port)")
            let range = NSRange(location: 0, length: serverURL.absoluteString.count)
            let matches = regularExpression.matches(in: serverURL.absoluteString, range: range)
            XCTAssertFalse(matches.isEmpty)
        }
    }

    func testGetRequest() {
        let expectation = self.expectation(description: "receive response")
        let url = URL(string: "http://127.0.0.1:\(port)")!
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
        let url = URL(string: "http://127.0.0.1:\(port)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("foo".utf8)
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

private class MockHTTPServerDelegate: HTTPServerDelegate {
    func server(_ server: HTTPServer, didStartListeningTo port: UInt16) {
    }

    func server(_ server: HTTPServer, didReceiveRequest context: HTTPRequestContext) {
        context.setContentLength(context.requestBody?.count ?? 0)
        context.setContentType(.plainText(.utf8))
        context.setValue(context.requestMethod, forResponse: "X-Request-Method")
        context.setValue(context.requestURL.absoluteString, forResponse: "X-Request-Url")
        let stream = context.respond(statusCode: 200)
        if let body = context.requestBody {
            stream.write(data: body)
        }
        stream.close()
    }

    func server(_ server: HTTPServer, didFailToHandle context: HTTPRequestContext, error: Error) {
        let body = Data(error.localizedDescription.utf8)
        context.setContentLength(body.count)
        context.setContentType(.plainText(.utf8))
        context.setValue(context.requestMethod, forResponse: "X-Request-Method")
        context.setValue(context.requestURL.absoluteString, forResponse: "X-Request-Url")
        let stream = context.respond(statusCode: 500)
        stream.write(data: body)
        stream.close()
    }
}
