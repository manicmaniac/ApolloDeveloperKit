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
        request.httpBodyStream = InputStream(data: Data(repeating: 0x41, count: 32768))
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
        waitForExpectations(timeout: 2.0, handler: nil)
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

    func server(_ server: HTTPServer, didReceiveRequest context: HTTPRequestContext) {
        context.setValue(context.requestMethod, forResponse: "X-Request-Method")
        context.setValue(context.requestURL.absoluteString, forResponse: "X-Request-Url")
        if let contentType = context.value(forRequest: "Content-Type") {
            context.setValue(contentType, forResponse: "Content-Type")
        }
        if let contentLength = context.requestBody?.count {
            context.setValue(String(contentLength), forResponse: "Content-Length")
        }
        let stream = context.respond(statusCode: 200)
        stream.write(data: context.requestBody ?? Data())
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
