//
//  ApolloDebugServerLoadTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 11/9/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class ApolloDebugServerLoadTests: XCTestCase {
    private static var store: ApolloStore!
    private static var client: ApolloClient!
    private static var server: ApolloDebugServer!
    private static var port = UInt16(0)

    override class func setUp() {
        let url = URL(string: "https://localhost/graphql")!
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

    func testGetBundleJS_withMaximumNumberOfClients() {
        let numberOfClients = 256
        let url = type(of: self).server.serverURL!.appendingPathComponent("bundle.js")
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpMaximumConnectionsPerHost = numberOfClients
        let session = URLSession(configuration: configuration)
        for index in (0..<numberOfClients) {
            let expectation = self.expectation(description: "response should be received (\(index))")
            let task = session.dataTask(with: url) { data, response, error in
                defer { expectation.fulfill() }
                if let error = error {
                    return XCTFail(String(describing: error))
                }
                guard let response = response as? HTTPURLResponse else {
                    return XCTFail("unexpected repsonse type")
                }
                XCTAssertEqual(response.statusCode, 200)
                XCTAssertEqual(response.allHeaderFields["Content-Type"] as? String, "application/javascript")
                guard let data = data else {
                    fatalError("URLSession.dataTask(with:) must pass either of error or data")
                }
                XCTAssertFalse(data.isEmpty)
            }
            task.resume()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
        session.invalidateAndCancel()
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
        let headerFields = ["Content-Type": "text/plain; charset=utf-8"]
        let response = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: httpVersion, headerFields: headerFields)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: HTTPURLResponse.localizedString(forStatusCode: 500).data(using: .utf8)!)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        queue.cancelAllOperations()
    }
}
