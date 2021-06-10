//
//  ApolloDebugServerTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 7/11/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import WebKit
import XCTest
@testable import ApolloDeveloperKit

class ApolloDebugServerTests: XCTestCase {
    private var store: ApolloStore!
    private var client: ApolloClient!
    private var server: ApolloDebugServer!
    private var port = UInt16(0)
    private var session: URLSession!

    override func setUpWithError() throws {
        let cache = DebuggableNormalizedCache(cache: InMemoryNormalizedCache())
        store = ApolloStore(cache: cache)
        let url = URL(string: "http://localhost/graphql")!
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockHTTPURLProtocol.self]
        let urlSessionClient = URLSessionClient(sessionConfiguration: configuration, callbackQueue: nil)
        let interceptorProvider = LegacyInterceptorProvider(client: urlSessionClient,
                                                            shouldInvalidateClientOnDeinit: true,
                                                            store: store)
        let networkTransport = DebuggableRequestChainNetworkTransport(interceptorProvider: interceptorProvider, endpointURL: url)
        client = ApolloClient(networkTransport: networkTransport, store: store)
        server = ApolloDebugServer(networkTransport: networkTransport, cache: cache, keepAliveInterval: 0.25)
        port = try server.start(randomPortIn: 49152...65535)
        session = URLSession(configuration: .test)
    }

    override func tearDown() {
        session.invalidateAndCancel()
        server.stop()
    }

    func testConsoleRedirection() {
        let consoleMessage = """
            Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
            Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.
            Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.
            Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
            """
        let html = """
            <!DOCTYPE html>
            <title>.</title>
            <script>
            window.onerror = (message, url, line, column, error) => {
                webkit.messageHandlers.onerror.postMessage(JSON.stringify(error));
            };
            const eventSource = new EventSource('events');
            eventSource.onerror = error => {
                webkit.messageHandlers.onerror.postMessage(JSON.stringify(error));
            };
            eventSource.onmessage = event => {
                webkit.messageHandlers.onmessage.postMessage(event.data);
            };
            eventSource.addEventListener('stdout', event => {
                webkit.messageHandlers.onstdout.postMessage(event.data);
            });
            webkit.messageHandlers.onload.postMessage({});
            </script>
            """
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        let expectationOnLoad = expectation(description: "'load' event should fire")
        let onLoadHandler = ScriptMessageHandlerBlock { _, _ in
            expectationOnLoad.fulfill()
        }
        configuration.userContentController.add(onLoadHandler, name: "onload")
        let onErrorHandler = ScriptMessageHandlerBlock { _, message in
            XCTFail(String(describing: message.body))
        }
        configuration.userContentController.add(onErrorHandler, name: "onerror")
        let expectationOnMessage = expectation(description: "'message' event should fire")
        let onMessageHandler = ScriptMessageHandlerBlock { _, _ in
            expectationOnMessage.fulfill()
        }
        configuration.userContentController.add(onMessageHandler, name: "onmessage")
        let expectationOnStdout = expectation(description: "'stdout' event should fire")
        let onStdoutHandler = ScriptMessageHandlerBlock { _, message in
            XCTAssertEqual(message.body as? String, consoleMessage)
            expectationOnStdout.fulfill()
        }
        configuration.userContentController.add(onStdoutHandler, name: "onstdout")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.loadHTMLString(html, baseURL: server.serverURL!)
        wait(for: [expectationOnLoad, expectationOnMessage], timeout: 20.0)
        let notification = Notification(name: .consoleDidWrite, object: ConsoleRedirection.shared, userInfo: [
            "data": Data(consoleMessage.utf8),
            "destination": ConsoleRedirection.Destination.standardOutput
        ])
        server.didReceiveConsoleDidWriteNotification(notification)
        wait(for: [expectationOnStdout], timeout: 5.0)
    }

    func testIsRunning() {
        XCTAssertTrue(server.isRunning)
    }

    func testServerURL() {
        XCTAssertEqual(server.serverURL?.scheme, "http")
        XCTAssertEqual(server.serverURL?.port, Int(port))
    }

    func testServerURLs_containsServerURL() throws {
        XCTAssert(server.serverURLs.contains(try XCTUnwrap(server.serverURL)))
    }

    func testHeadFavicon() {
        let url = server.serverURL!.appendingPathComponent("favicon.png")
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
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "image/png")
            XCTAssertGreaterThan(response.expectedContentLength, 0)
            XCTAssertTrue(data.isEmpty)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetFavicon() {
        let url = server.serverURL!.appendingPathComponent("favicon.png")
        let expectation = self.expectation(description: "response should be received")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "image/png")
            XCTAssertGreaterThan(response.expectedContentLength, 0)
            XCTAssertFalse(data.isEmpty)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testHeadIndex() {
        let url = server.serverURL!
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/html; charset=utf-8")
            XCTAssertGreaterThan(response.expectedContentLength, 0)
            XCTAssertTrue(data.isEmpty)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetIndex() {
        let url = server.serverURL!
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: url) { data, response, error in
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
        let url = server.serverURL!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: request) { data, response, error in
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
        let url = server.serverURL!.appendingPathComponent("bundle.js")
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "application/javascript")
            XCTAssertGreaterThan(response.expectedContentLength, 0)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetBundleJS() {
        let url = server.serverURL!.appendingPathComponent("bundle.js")
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "application/javascript")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            XCTAssertFalse(data.isEmpty)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testHeadStyleCSS() {
        let url = server.serverURL!.appendingPathComponent("style.css")
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/css")
            XCTAssertGreaterThan(response.expectedContentLength, 0)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetStyleCSS() {
        let url = server.serverURL!.appendingPathComponent("style.css")
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: url) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 200)
            XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "text/css")
            guard let data = data else {
                fatalError("URLSession.dataTask(with:) must pass either of error or data")
            }
            XCTAssertFalse(data.isEmpty)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testGetInvalidURL() {
        let url = server.serverURL!.appendingPathComponent("invalid")
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: url) { data, response, error in
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
        let url = server.serverURL!.appendingPathComponent("events")
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: request) { data, response, error in
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
        let url = server.serverURL!.appendingPathComponent("events")
        let expectationForResponse = expectation(description: "response should be received")
        let expectationForData = expectation(description: "data should be received")
        expectationForData.expectedFulfillmentCount = 2
        let handler = ChunkedURLSessionDataTaskHandler()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: configuration, delegate: handler, delegateQueue: nil)
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
                XCTAssertEqual(data, Data(":\n\n".utf8))
            } else {
                XCTAssert(data.starts(with: Data("data: ".utf8)))
                // Drop first 5 letters (`data: `)
                let jsonData = data.dropFirst(5)
                let expected: NSDictionary = [
                    "state": [
                        "queries": [],
                        "mutations": []
                    ],
                    "dataWithOptimisticResults": [:]
                ]
                do {
                    let jsonObject = try JSONSerialization.jsonObject(with: jsonData) as? NSDictionary
                    XCTAssertEqual(jsonObject, expected)
                } catch let error {
                    XCTFail(String(describing: error))
                }
            }
        }
        handler.urlSessionTaskDidCompleteWithError = { session, task, error in
            if let error = error as NSError? {
                guard error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled else {
                    return XCTFail(String(describing: error))
                }
            }
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
        session.invalidateAndCancel()
    }

    func testHeadRequest() {
        let url = server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: request) { data, response, error in
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
        let url = server.serverURL!.appendingPathComponent("request")
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: url) { data, response, error in
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
        let url = server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = query
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: request) { data, response, error in
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
            guard let jsonObject = (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary else {
                return XCTFail("failed to parse JSON response")
            }
            XCTAssertEqual(jsonObject, queryResponseJSONObject)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPostRequest_withMutation() {
        let url = server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = mutation
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: request) { data, response, error in
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
            guard let jsonObject = (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary else {
                return XCTFail("failed to parse JSON response")
            }
            XCTAssertEqual(jsonObject, mutationResponseJSONObject)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPostRequest_whenAServerErrorOccurs() {
        let url = server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = serverError
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: request) { data, response, error in
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
            guard let jsonObject = (try? JSONSerialization.jsonObject(with: data)) as? NSDictionary else {
                return XCTFail("failed to parse JSON response")
            }
            XCTAssertEqual(jsonObject, serverErrorResponseJSONObject)
        }
        task.resume()
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPostRequest_withZeroByteData() {
        let url = server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data()
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: request) { data, response, error in
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

    func testPostRequest_withServerInternalError() {
        let url = server.serverURL!.appendingPathComponent("request")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = serverInternalError
        let expectation = self.expectation(description: "response should be received")
        let task = session.dataTask(with: request) { data, response, error in
            defer { expectation.fulfill() }
            if let error = error {
                return XCTFail(String(describing: error))
            }
            guard let response = response as? HTTPURLResponse else {
                return XCTFail("unexpected response type")
            }
            XCTAssertEqual(response.statusCode, 500)
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
        guard let requestJSONObject = (try? JSONSerialization.jsonObject(with: requestBody)) as? NSDictionary else {
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
            sendDataResponse(url: url, data: serverErrorResponse, statusCode: 200)
        } else if query.hasPrefix("serverInternalError") {
            sendErrorResponse(url: url, statusCode: 500)
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
        client?.urlProtocol(self, didLoad: Data(HTTPURLResponse.localizedString(forStatusCode: statusCode).utf8))
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

private class ScriptMessageHandlerBlock: NSObject, WKScriptMessageHandler {
    private let block: (WKUserContentController, WKScriptMessage) -> Void

    init(_ block: @escaping (WKUserContentController, WKScriptMessage) -> Void) {
        self.block = block
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        block(userContentController, message)
    }
}

// MARK: Fixtures

private let query = Data("""
    {
        "operationName": "query",
        "query": "query Employee($id: ID!) { employee(id: $id) { id name department { name } } }",
        "variables": {
            "id": "42"
        }
    }
    """.utf8)

private let queryJSONObject = try! JSONSerialization.jsonObject(with: query) as! NSDictionary

private let queryResponse = Data("""
    {
        "employee": {
            "id": "42",
            "name": "John Doe",
            "department": {
                "name": "Human Resources"
            }
        }
    }
    """.utf8)

private let queryResponseJSONObject = try! JSONSerialization.jsonObject(with: queryResponse) as! NSDictionary

private let mutation = Data("""
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
    """.utf8)

private let mutationJSONObject = try! JSONSerialization.jsonObject(with: mutation) as! NSDictionary

private let mutationResponse = Data("""
    {
        "employee": {
            "id": "43",
        }
    }
    """.utf8)

private let mutationResponseJSONObject = try! JSONSerialization.jsonObject(with: mutationResponse) as! NSDictionary

private let serverError = Data("""
    {
        "operationName": "serverError",
        "query": "serverError"
    }
    """.utf8)

private let serverErrorJSONObject = try! JSONSerialization.jsonObject(with: serverError) as! NSDictionary

private let serverErrorResponse = Data("""
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
    """.utf8)

private let serverErrorResponseJSONObject = try! JSONSerialization.jsonObject(with: serverErrorResponse) as! NSDictionary

private let serverInternalError = Data("""
    {
        "operationName": "serverInternalError",
        "query": "serverInternalError"
    }
    """.utf8)
