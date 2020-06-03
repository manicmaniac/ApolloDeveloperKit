//
//  OperationStoreControllerTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 2/11/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class OperationStoreControllerTests: XCTestCase {
    private var store: MockOperationStore!
    private var controller: OperationStoreController!
    private var networkTransport: DebuggableNetworkTransport!

    override func setUp() {
        store = MockOperationStore()
        controller = OperationStoreController(store: store)
        networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport())
    }

    func testNetworkTransportWillSendOperation() {
        controller.networkTransport(networkTransport, willSendOperation: MockGraphQLQuery())
        let expectation = self.expectation(description: "An invocation should be recoreded")
        controller.queue.async {
            defer { expectation.fulfill() }
            XCTAssertEqual(self.store.invocationHistory.count, 1)
            guard case .add? = self.store.invocationHistory.first else {
                return XCTFail()
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testNetworkTransportDidSendOperation_withSuccessfulQuery() {
        let query = MockGraphQLQuery()
        let response = GraphQLResponse(operation: query, body: [:])
        controller.networkTransport(networkTransport, didSendOperation: query, result: .success(response))
        let expectation = self.expectation(description: "An invocation should be recoreded")
        controller.queue.async {
            defer { expectation.fulfill() }
            XCTAssertEqual(self.store.invocationHistory.count, 1)
            guard case .setSuccess(_, let errors)? = self.store.invocationHistory.first, errors.isEmpty else {
                return XCTFail()
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testNetworkTransportDidSendOperation_withSuccessfulMutation() {
        let mutation = MockGraphQLMutation()
        let response = GraphQLResponse(operation: mutation, body: [:])
        controller.networkTransport(networkTransport, didSendOperation: mutation, result: .success(response))
        let expectation = self.expectation(description: "An invocation should be recoreded")
        controller.queue.async {
            defer { expectation.fulfill() }
            XCTAssertEqual(self.store.invocationHistory.count, 1)
            guard case .setSuccess(_, let errors)? = self.store.invocationHistory.first, errors.isEmpty else {
                return XCTFail()
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testNetworkTransportDidSendOperation_withSuccessfulSubscription() {
        let subscription = MockGraphQLSubscription()
        let response = GraphQLResponse(operation: subscription, body: [:])
        controller.networkTransport(networkTransport, didSendOperation: subscription, result: .success(response))
        let expectation = self.expectation(description: "An invocation should be recoreded")
        controller.queue.async {
            defer { expectation.fulfill() }
            XCTAssertEqual(self.store.invocationHistory.count, 1)
            guard case .setSuccess(_, let errors)? = self.store.invocationHistory.first, errors.isEmpty else {
                return XCTFail()
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testNetworkTransportDidSendOperation_withNetworkErrorQuery() {
        let query = MockGraphQLQuery()
        let error = URLError(.notConnectedToInternet)
        controller.networkTransport(networkTransport, didSendOperation: query, result: .failure(error))
        let expectation = self.expectation(description: "An invocation should be recoreded")
        controller.queue.async {
            defer { expectation.fulfill() }
            XCTAssertEqual(self.store.invocationHistory.count, 1)
            guard case .setFailure(_, URLError.notConnectedToInternet)? = self.store.invocationHistory.first else {
                return XCTFail()
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testNetworkTransportDidSendOperation_withGraphQLErrorQuery() {
        let query = MockGraphQLQuery()
        let response = GraphQLResponse(operation: query, body: [
            "errors": [
                [
                    "message": "Name for character with ID 1002 could not be fetched."
                ]
            ]
        ])
        controller.networkTransport(networkTransport, didSendOperation: query, result: .success(response))
        let expectation = self.expectation(description: "An invocation should be recoreded")
        controller.queue.async {
            defer { expectation.fulfill() }
            XCTAssertEqual(self.store.invocationHistory.count, 1)
            guard case .setSuccess(_, let errors)? = self.store.invocationHistory.first, errors.count == 1 else {
                return XCTFail()
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }
}

private class MockOperationStore: OperationStore {
    enum Invocation<Operation: GraphQLOperation> {
        case add(Operation)
        case setFailure(Operation, Error)
        case setSuccess(Operation, [Error])
    }

    var invocationHistory = [Invocation<AnyGraphQLOperation>]()

    func add<Operation>(_ operation: Operation) where Operation : GraphQLOperation {
        invocationHistory.append(.add(AnyGraphQLOperation(operation)))
    }

    func setFailure<Operation>(for operation: Operation, networkError: Error) where Operation : GraphQLOperation {
        invocationHistory.append(.setFailure(AnyGraphQLOperation(operation), networkError))
    }

    func setSuccess<Operation>(for operation: Operation, graphQLErrors: [Error]) where Operation : GraphQLOperation {
        invocationHistory.append(.setSuccess(AnyGraphQLOperation(operation), graphQLErrors))
    }

    var jsonValue: JSONValue {
        return ""
    }
}
