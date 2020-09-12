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
        let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport())
        XCTAssertEqual(networkTransport.clientName, "clientName")
    }

    func testSetClientName() {
        let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport())
        networkTransport.clientName = "foo"
        XCTAssertEqual(networkTransport.clientName, "foo")
    }

    func testGetClientVersion() {
        let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport())
        XCTAssertEqual(networkTransport.clientVersion, "clientVersion")
    }

    func testSetClientVersion() {
        let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport())
        networkTransport.clientVersion = "foo"
        XCTAssertEqual(networkTransport.clientVersion, "foo")
    }

    func testSendOperationWithCompletionHandler_whenResponseIsNotNilButErrorIsNil() {
        let operation = MockGraphQLQuery()
        let response = GraphQLResponse<MockGraphQLQuery.Data>(operation: operation, body: ["foo": "bar"])
        let mockNetworkTransport = MockNetworkTransport()
        mockNetworkTransport.append(response: response)
        let networkTransport = DebuggableNetworkTransport(networkTransport: mockNetworkTransport)
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
        XCTAssert(cancellable is MockCancellable)
        waitForExpectations(timeout: 0.25, handler: nil)
        XCTAssert(mockNetworkTransport.isResultsEmpty)
    }

    func testSendOperationWithCompletionHandler_whenResponseIsNilAndErrorIsNotNil() {
        let operation = MockGraphQLQuery()
        let urlError = URLError(.badURL)
        let mockNetworkTransport = MockNetworkTransport()
        mockNetworkTransport.append(error: urlError)
        let networkTransport = DebuggableNetworkTransport(networkTransport: mockNetworkTransport)
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
        XCTAssert(cancellable is MockCancellable)
        waitForExpectations(timeout: 0.25, handler: nil)
        XCTAssert(mockNetworkTransport.isResultsEmpty)
    }
}
