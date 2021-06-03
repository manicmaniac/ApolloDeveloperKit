//
//  DebuggableRequestChainNetworkTransportTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 5/31/21.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class DebuggableRequestChainNetworkTransportTests: XCTestCase {
    private let url = URL(string: "https://localhost/graphql")!

    func testInterceptorProviderWillSendOperation() {
        let interceptorProvider = MockInterceptorProvider()
        let operation = MockGraphQLQuery()
        let networkTransport = DebuggableRequestChainNetworkTransport(interceptorProvider: interceptorProvider, endpointURL: url)
        let delegateHandler = DebuggableNetworkTransportDelegateHandler()
        let expectation = self.expectation(description: "The corresponding delegate method should be called.")
        delegateHandler.networkTransportWillSendOperation = { receivedNetworkTransport, receivedOperation in
            XCTAssert(receivedNetworkTransport === networkTransport)
            XCTAssertEqual(receivedOperation.operationType, operation.operationType)
            XCTAssertEqual(receivedOperation.operationName, operation.operationName)
            XCTAssertEqual(receivedOperation.operationDefinition, operation.operationDefinition)
            XCTAssertEqual(receivedOperation.operationIdentifier, operation.operationIdentifier)
            expectation.fulfill()
        }
        networkTransport.delegate = delegateHandler
        networkTransport.interceptorProvider(interceptorProvider, willSendOperation: operation)
        waitForExpectations(timeout: 0.5)
    }

    func testInterceptorProviderDidSendOperation_withSuccess() {
        let interceptorProvider = MockInterceptorProvider()
        let operation = MockGraphQLQuery()
        let networkTransport = DebuggableRequestChainNetworkTransport(interceptorProvider: interceptorProvider, endpointURL: url)
        let delegateHandler = DebuggableNetworkTransportDelegateHandler()
        let expectation = self.expectation(description: "The corresponding delegate method should be called.")
        delegateHandler.networkTransportDidSendOperation = { receivedNetworkTransport, receivedOperation, receivedResult in
            XCTAssert(receivedNetworkTransport === networkTransport)
            XCTAssertEqual(receivedOperation.operationType, operation.operationType)
            XCTAssertEqual(receivedOperation.operationName, operation.operationName)
            XCTAssertEqual(receivedOperation.operationDefinition, operation.operationDefinition)
            XCTAssertEqual(receivedOperation.operationIdentifier, operation.operationIdentifier)
            XCTAssertNotNil(try? receivedResult.get())
            expectation.fulfill()
        }
        networkTransport.delegate = delegateHandler
        let graphQLResult = GraphQLResult<MockGraphQLQuery.Data>(data: nil,
                                                                 extensions: nil,
                                                                 errors: nil,
                                                                 source: .server,
                                                                 dependentKeys: nil)
        networkTransport.interceptorProvider(interceptorProvider, didSendOperation: operation, result: .success(graphQLResult))
        waitForExpectations(timeout: 0.5)
    }
}

private class MockInterceptorProvider: InterceptorProvider {
    func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation : GraphQLOperation {
        return []
    }
}

private class DebuggableNetworkTransportDelegateHandler: DebuggableNetworkTransportDelegate {
    var networkTransportWillSendOperation: ((NetworkTransport, AnyGraphQLOperation) -> Void)?
    var networkTransportDidSendOperation: ((NetworkTransport, AnyGraphQLOperation, Result<GraphQLResult<AnyGraphQLOperation.Data>, Error>) -> Void)?

    func networkTransport<Operation>(_ networkTransport: NetworkTransport, willSendOperation operation: Operation) where Operation : GraphQLOperation {
        networkTransportWillSendOperation?(networkTransport, AnyGraphQLOperation(operation))
    }

    func networkTransport<Operation>(_ networkTransport: NetworkTransport, didSendOperation operation: Operation, result: Result<GraphQLResult<Operation.Data>, Error>) where Operation : GraphQLOperation {
        networkTransportDidSendOperation?(networkTransport, AnyGraphQLOperation(operation), result.map(GraphQLResult.init(_:)))
    }
}
