//
//  ApolloDebugServerTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 7/11/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class ApolloDebugServerTests: XCTestCase {
    private static var store: ApolloStore!
    private static var client: ApolloClient!
    private static var server: ApolloDebugServer!
    private static var port = UInt16(0)

    override class func setUp() {
        let url = URL(string: "http://localhost/graphql")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockHTTPURLProtocol.self]
        let networkTransport = DebuggableNetworkTransport(networkTransport: HTTPNetworkTransport(url: url, configuration: configuration, sendOperationIdentifiers: false))
        let cache = DebuggableNormalizedCache(cache: InMemoryNormalizedCache())
        store = ApolloStore(cache: cache)
        client = ApolloClient(networkTransport: networkTransport, store: store)
        server = ApolloDebugServer(networkTransport: networkTransport, cache: cache, keepAliveInterval: 0.25)
        port = try! server.start(randomPortIn: 49152...65535)
    }

    override class func tearDown() {
        server.stop()
    }

    func testIsRunning() {
        XCTAssertTrue(type(of: self).server.isRunning)
    }

    func testServerURL() {
        XCTAssertEqual(type(of: self).server.serverURL?.scheme, "http")
        XCTAssertEqual(type(of: self).server.serverURL?.port, Int(type(of: self).port))
    }

    func testHeadIndex() {
        let url = type(of: self).server.serverURL!
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/html; charset=utf-8")
            XCTAssertGreaterThan(response.expectedContentLength, 0)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetIndex() {
        let url = type(of: self).server.serverURL!
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/html; charset=utf-8")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            guard let htmlString = String(data: data, encoding: .utf8) else {
                return XCTFail("failed to decode data as UTF-8")
            }
            XCTAssertTrue(htmlString.hasPrefix("<!doctype html>"))
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPostIndex() {
        let url = type(of: self).server.serverURL!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 405)
            XCTAssertEqual(response.allHeaderFields["Allow"] as? String, "HEAD, GET")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            guard let string = String(data: data, encoding: .utf8) else {
                return XCTFail("failed to decode data as UTF-8")
            }
            XCTAssertEqual(string, "405 method not allowed\n")
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testHeadBundleJS() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("bundle.js")
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/javascript; charset=utf-8")
            XCTAssertGreaterThan(response.expectedContentLength, 0)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetBundleJS() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("bundle.js")
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/javascript; charset=utf-8")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            XCTAssertFalse(data.isEmpty)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testHeadStyleCSS() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("style.css")
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/css; charset=utf-8")
            XCTAssertGreaterThan(response.expectedContentLength, 0)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetStyleCSS() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("style.css")
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/css; charset=utf-8")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            XCTAssertFalse(data.isEmpty)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetInvalidURL() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("invalid")
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 404)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/plain; charset=utf-8")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            guard let string = String(data: data, encoding: .utf8) else {
                return XCTFail("failed to decode data as UTF-8")
            }
            XCTAssertEqual(string, "404 not found\n")
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testHeadEvents() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("events")
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/event-stream")
            XCTAssertEqual(response.allHeaderFields["Transfer-Encoding"] as? String, "chunked")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            XCTAssertTrue(data.isEmpty)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetEvents() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("events")
        let expectationForResponse = expectation(description: "response should be received")
        let expectationForData = expectation(description: "data should be received")
        expectationForData.expectedFulfillmentCount = 2
        let handler = ChunkedURLSessionDataTaskHandler()
        let session = URLSession(configuration: .default, delegate: handler, delegateQueue: nil)
        let task = session.dataTask(with: url)
        handler.urlSessionDataTaskDidReceiveResponseWithCompletionHandler = { session, task, response, completionHandler in
            defer { expectationForResponse.fulfill() }
            let response = response as! HTTPURLResponse
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/event-stream")
            // Somehow `URLSessionDataTask` converts Transfer-Encoding to `Identity` even if it was actually `chunked`.
            XCTAssertEqual(response.allHeaderFields["Transfer-Encoding"] as? String, "Identity")
            completionHandler(.allow)
        }
        var urlSessionDataTaskDidReceiveDataIsCalled = false
        handler.urlSessionDataTaskDidReceiveData = { session, task, data in
            defer {
                urlSessionDataTaskDidReceiveDataIsCalled = true
                expectationForData.fulfill()
            }
            if urlSessionDataTaskDidReceiveDataIsCalled {
                // It should be just a *ping* data
                XCTAssertEqual(data, ":\n\n".data(using: .ascii))
            } else {
                XCTAssert(data.starts(with: "data: ".data(using: .ascii)!))
                // Drop first 5 letters (`data: `)
                let jsonData = data.dropFirst(5)
                let expected: NSDictionary = [
                    "state": [
                        "queries": [:],
                        "mutations": [:]
                    ],
                    "action": [:],
                    "dataWithOptimisticResults": [:]
                ]
                XCTAssertNoThrow({
                    let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? NSDictionary
                    XCTAssertEqual(jsonObject, expected)
                })
            }
        }
        handler.urlSessionTaskDidCompleteWithError = { session, task, error in
            if let error = error as NSError? {
                guard error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled else {
                    return XCTFail(error.localizedDescription)
                }
            }
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
        session.invalidateAndCancel()
    }

    func testHeadRequest() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 405)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/plain; charset=utf-8")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            XCTAssertTrue(data.isEmpty)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetRequest() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("request")
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 405)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/plain; charset=utf-8")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            guard let string = String(data: data, encoding: .utf8) else {
                return XCTFail("failed to decode data as UTF-8")
            }
            XCTAssertEqual(string, "405 method not allowed\n")
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPostRequest_withQuery() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = query
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "application/json")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            guard let jsonObject = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary else {
                return XCTFail("failed to parse JSON response")
            }
            XCTAssertEqual(jsonObject, queryResponseJSONObject)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPostRequest_withMutation() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = mutation
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "application/json")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            guard let jsonObject = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary else {
                return XCTFail("failed to parse JSON response")
            }
            XCTAssertEqual(jsonObject, mutationResponseJSONObject)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPostRequest_whenAServerErrorOccurs() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = serverError
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 400)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "application/json")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            guard let jsonObject = (try? JSONSerialization.jsonObject(with: data, options: [])) as? NSDictionary else {
                return XCTFail("failed to parse JSON response")
            }
            XCTAssertEqual(jsonObject, serverErrorResponseJSONObject)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPostRequest_withZeroByteData() {
        let url = type(of: self).server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data()
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 400)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}

private class MockHTTPURLProtocol: URLProtocol {
    private let httpVersion = "1.1"
    private let queue = OperationQueue()

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard !Thread.isMainThread else {
            return queue.addOperation(startLoading)
        }
        guard let url = request.url else { return }
        guard url.absoluteString == "http://localhost/graphql" else {
            return sendErrorResponse(url: url, statusCode: 404)
        }
        guard request.httpMethod == "POST" else {
            return sendErrorResponse(url: url, statusCode: 405)
        }
        guard let httpBodyStream = request.httpBodyStream else {
            return sendErrorResponse(url: url, statusCode: 400)
        }
        httpBodyStream.open()
        let requestBody = readData(from: httpBodyStream, upto: 8192)
        httpBodyStream.close()
        guard let requestJSONObject = (try? JSONSerialization.jsonObject(with: requestBody, options: [])) as? NSDictionary else {
            return sendErrorResponse(url: url, statusCode: 400)
        }
        guard let query = requestJSONObject["query"] as? String else {
            return sendErrorResponse(url: url, statusCode: 400)
        }
        if query.hasPrefix("query") {
            sendDataResponse(url: url, data: queryResponse)
        } else if query.hasPrefix("mutation") {
            sendDataResponse(url: url, data: mutationResponse)
        } else if query.hasPrefix("serverError") {
            sendDataResponse(url: url, data: serverErrorResponse, statusCode: 400)
        } else {
            sendErrorResponse(url: url, statusCode: 400)
        }
    }

    override func stopLoading() {
        queue.cancelAllOperations()
    }

    private func sendErrorResponse(url: URL, statusCode: Int) {
        let headerFields = ["Content-Type": "text/plain; charset=utf-8"]
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: HTTPURLResponse.localizedString(forStatusCode: statusCode).data(using: .utf8)!)
        client?.urlProtocolDidFinishLoading(self)
    }

    private func sendDataResponse(url: URL, data: Data, statusCode: Int = 200) {
        let headerFields = ["Content-Type": "application/json"]
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        let responseBody = data
        client?.urlProtocol(self, didLoad: responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }

    private func readData(from inputStream: InputStream, upto bufferSize: Int) -> Data {
        let data = NSMutableData(length: bufferSize)!
        var totalRead = 0
        while inputStream.hasBytesAvailable {
            totalRead += inputStream.read(data.mutableBytes.assumingMemoryBound(to: UInt8.self).advanced(by: totalRead), maxLength: bufferSize - totalRead)
        }
        return data.subdata(with: NSRange(location: 0, length: totalRead))
    }
}

private class ChunkedURLSessionDataTaskHandler: NSObject, URLSessionDataDelegate {
    var urlSessionDataTaskDidReceiveResponseWithCompletionHandler: ((URLSession, URLSessionDataTask, URLResponse, @escaping (URLSession.ResponseDisposition) -> Void) -> Void)?
    var urlSessionDataTaskDidReceiveData: ((URLSession, URLSessionDataTask, Data) -> Void)?
    var urlSessionTaskDidCompleteWithError: ((URLSession, URLSessionTask, Error?) -> Void)?

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        urlSessionDataTaskDidReceiveResponseWithCompletionHandler?(session, dataTask, response, completionHandler) ?? completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        urlSessionDataTaskDidReceiveData?(session, dataTask, data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        urlSessionTaskDidCompleteWithError?(session, task, error)
    }
}

// MARK: Fixtures

private let query = """
    {
        "operationName": "query",
        "query": "query Employee($id: ID!) { employee(id: $id) { id name department { name } } }",
        "variables": {
            "id": "42"
        }
    }
    """.data(using: .utf8)!

private let queryJSONObject = try! JSONSerialization.jsonObject(with: query, options: []) as! NSDictionary

private let queryResponse = """
    {
        "employee": {
            "id": "42",
            "name": "John Doe",
            "department": {
                "name": "Human Resources"
            }
        }
    }
    """.data(using: .utf8)!

private let queryResponseJSONObject = try! JSONSerialization.jsonObject(with: queryResponse, options: []) as! NSDictionary

private let mutation = """
    {
        "operationName": "mutation",
        "query": "mutation AddEmployee($input: AddEmployeeInput) { addEmployee(input: $input) { id } }",
        "variables": {
            "input": {
                "name": "New Joiner",
                "age": 30,
                "isManager": true
            }
        }
    }
    """.data(using: .utf8)!

private let mutationJSONObject = try! JSONSerialization.jsonObject(with: mutation, options: []) as! NSDictionary

private let mutationResponse = """
    {
        "employee": {
            "id": "43",
        }
    }
    """.data(using: .utf8)!

private let mutationResponseJSONObject = try! JSONSerialization.jsonObject(with: mutationResponse, options: []) as! NSDictionary

private let serverError = """
    {
        "operationName": "serverError",
        "query": "serverError"
    }
    """.data(using: .utf8)!

private let serverErrorJSONObject = try! JSONSerialization.jsonObject(with: serverError, options: []) as! NSDictionary

private let serverErrorResponse = """
    {
        "data": {
            "employees": null
        },
        "errors": [
            {
                "message": "Error",
                "locations": [
                    {
                        "line": 2,
                        "column": 3
                    }
                ],
                "path": [
                    "employees"
                ]
            }
        ]
    }
    """.data(using: .utf8)!

private let serverErrorResponseJSONObject = try! JSONSerialization.jsonObject(with: serverErrorResponse, options: []) as! NSDictionary
