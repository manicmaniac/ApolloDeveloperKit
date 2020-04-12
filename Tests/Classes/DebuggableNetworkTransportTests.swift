//
//  DebuggableNetworkTransportTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/17/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class DebuggableNetworkTransportTests: XCTestCase {
    func testGetClientName() {
        let response: GraphQLResponse<MockGraphQLQuery.Data>? = nil
        let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport(response: response, error: nil))
        XCTAssertEqual(networkTransport.clientName, "clientName")
    }

    func testSetClientName() {
        let response: GraphQLResponse<MockGraphQLQuery.Data>? = nil
        let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport(response: response, error: nil))
        networkTransport.clientName = "foo"
        XCTAssertEqual(networkTransport.clientName, "foo")
    }

    func testGetClientVersion() {
        let response: GraphQLResponse<MockGraphQLQuery.Data>? = nil
        let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport(response: response, error: nil))
        XCTAssertEqual(networkTransport.clientVersion, "clientVersion")
    }

    func testSetClientVersion() {
        let response: GraphQLResponse<MockGraphQLQuery.Data>? = nil
        let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport(response: response, error: nil))
        networkTransport.clientVersion = "foo"
        XCTAssertEqual(networkTransport.clientVersion, "foo")
    }

    func testSendOperationWithCompletionHandler_whenResponseIsNotNilButErrorIsNil() {
        let operation = MockGraphQLQuery()
        let response = GraphQLResponse<MockGraphQLQuery.Data>(operation: operation, body: ["foo": "bar"])
        let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport(response: response, error: nil))
        let expectation = self.expectation(description: "completionHandler should be called")
        let cancellable = networkTransport.send(operation: operation) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.body.count, 1)
            case .failure:
                XCTFail()
            }
            expectation.fulfill()
        }
        XCTAssertTrue(cancellable is MockCancellable)
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testSendOperationWithCompletionHandler_whenResponseIsNilAndErrorIsNotNil() {
        let operation = MockGraphQLQuery()
        let response: GraphQLResponse<MockGraphQLQuery.Data>? = nil
        let urlError = URLError(.badURL)
        let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport(response: response, error: urlError))
        let expectation = self.expectation(description: "completionHandler should be called")
        let cancellable = networkTransport.send(operation: operation) { result in
            switch result {
            case .success:
                XCTFail()
            case .failure(let error):
                XCTAssertTrue(error as NSError? === urlError as NSError)
            }
            expectation.fulfill()
        }
        XCTAssertTrue(cancellable is MockCancellable)
        waitForExpectations(timeout: 0.25, handler: nil)
    }
}
