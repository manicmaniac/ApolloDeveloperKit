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
        controller.queue.sync {
            XCTAssertEqual(store.invocationHistory.count, 1)
            guard case .add? = store.invocationHistory.first else {
                return XCTFail()
            }
        }
    }

    func testNetworkTransportDidSendOperation_withSuccessfulQuery() {
        let query = MockGraphQLQuery()
        let response = GraphQLResponse(operation: query, body: [:])
        controller.networkTransport(networkTransport, didSendOperation: query, result: .success(response))
        controller.queue.sync {
            XCTAssertEqual(store.invocationHistory.count, 1)
            guard case .setSuccess(_, let errors)? = store.invocationHistory.first, errors.isEmpty else {
                return XCTFail()
            }
        }
    }

    func testNetworkTransportDidSendOperation_withSuccessfulMutation() {
        let mutation = MockGraphQLMutation()
        let response = GraphQLResponse(operation: mutation, body: [:])
        controller.networkTransport(networkTransport, didSendOperation: mutation, result: .success(response))
        controller.queue.sync {
            XCTAssertEqual(store.invocationHistory.count, 1)
            guard case .setSuccess(_, let errors)? = store.invocationHistory.first, errors.isEmpty else {
                return XCTFail()
            }
        }
    }

    func testNetworkTransportDidSendOperation_withSuccessfulSubscription() {
        let subscription = MockGraphQLSubscription()
        let response = GraphQLResponse(operation: subscription, body: [:])
        controller.networkTransport(networkTransport, didSendOperation: subscription, result: .success(response))
        controller.queue.sync {
            XCTAssertEqual(store.invocationHistory.count, 1)
            guard case .setSuccess(_, let errors)? = store.invocationHistory.first, errors.isEmpty else {
                return XCTFail()
            }
        }
    }

    func testNetworkTransportDidSendOperation_withNetworkErrorQuery() {
        let query = MockGraphQLQuery()
        let error = URLError(.notConnectedToInternet)
        controller.networkTransport(networkTransport, didSendOperation: query, result: .failure(error))
        controller.queue.sync {
            XCTAssertEqual(store.invocationHistory.count, 1)
            guard case .setFailure(_, URLError.notConnectedToInternet)? = store.invocationHistory.first else {
                return XCTFail()
            }
        }
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
        controller.queue.sync {
            XCTAssertEqual(store.invocationHistory.count, 1)
            guard case .setSuccess(_, let errors)? = store.invocationHistory.first, errors.count == 1 else {
                return XCTFail()
            }
        }
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

    var state: State {
        return State(mutations: [], queries: [])
    }
}
