//
//  HTTPServerChunkedEncodingTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 3/1/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class HTTPServerChunkedEncodingTests: XCTestCase {
    private var server: HTTPServer!
    private var mockHTTPServerDelegate: MockHTTPServerDelegate!
    private var port = UInt16(0)
    private var chunkedEncodingSessionTaskHandler: ChunkedEncodingSessionTaskHandler!
    private var session: URLSession!

    override func setUp() {
        server = HTTPServer()
        mockHTTPServerDelegate = MockHTTPServerDelegate()
        server.delegate = mockHTTPServerDelegate
        port = try! server.start(randomPortIn: 49152...65535) // macOS ephemeral ports
        chunkedEncodingSessionTaskHandler = ChunkedEncodingSessionTaskHandler()
        session = URLSession(configuration: .test, delegate: chunkedEncodingSessionTaskHandler, delegateQueue: nil)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        server.stop()
    }

    func testPostRequestWithChunkedEncoding() {
        let expectation = self.expectation(description: "receive response")
        let url = URL(string: "http://127.0.0.1:\(port)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBodyStream = InputStream(data: Data(repeating: 0x41, count: 1024))
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue("keep-alive", forHTTPHeaderField: "Connection")
        let task = session.dataTask(with: request) { data, response, error in
            let response = response as? HTTPURLResponse
            XCTAssertEqual(response?.statusCode, 500)
            XCTAssertNil(error)
            let headerFields = response?.allHeaderFields as? [String: String]
            XCTAssertEqual(headerFields?["Content-Type"], "text/plain; charset=utf-8")
            XCTAssertEqual(headerFields?["Content-Length"], "55")
            XCTAssertEqual(headerFields?["X-Request-Method"], "POST")
            XCTAssertEqual(headerFields?["X-Request-Url"], url.absoluteString + "/")
            let bodyString = data.flatMap { data in String(data: data, encoding: .utf8) }
            XCTAssertEqual(bodyString, "Failed to parse the given HTTP body encoded in chunked.")
            expectation.fulfill()
        }
        task.resume()
        waitForExpectations(timeout: 0.25, handler: nil)
    }
}

private class ChunkedEncodingSessionTaskHandler: NSObject, URLSessionDataDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, needNewBodyStream completionHandler: @escaping (InputStream?) -> Void) {
        let data = Data(repeating: 0x77, count: 1024)
        let inputStream = InputStream(data: data)
        completionHandler(inputStream)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    }
}

private class MockHTTPServerDelegate: HTTPServerDelegate {
    func server(_ server: HTTPServer, didStartListeningTo port: UInt16) {
    }

    func server(_ server: HTTPServer, didReceiveRequest request: URLRequest, connection: HTTPConnection) {
        var headerFields: [String: String] = [
            "X-Request-Method": request.httpMethod!,
            "X-Request-Url": request.url!.absoluteString
        ]
        if let contentType = request.value(forHTTPHeaderField: "Content-Type") {
            headerFields["Content-Type"] = contentType
        }
        if let contentLength = request.httpBody?.count {
            headerFields["Content-Length"] = String(contentLength)
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: connection.httpVersion, headerFields: headerFields)!
        connection.write(response: response, body: request.httpBody)
        connection.close()
    }

    func server(_ server: HTTPServer, didFailToHandle request: URLRequest, connection: HTTPConnection, error: Error) {
        let body = error.localizedDescription.data(using: .utf8)!
        let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: connection.httpVersion, headerFields: [
            "Content-Length": String(body.count),
            "Content-Type": "text/plain; charset=utf-8",
            "X-Request-Method": request.httpMethod!,
            "X-Request-Url": request.url!.absoluteString
        ])!
        connection.write(response: response, body: body)
        connection.close()
    }
}
