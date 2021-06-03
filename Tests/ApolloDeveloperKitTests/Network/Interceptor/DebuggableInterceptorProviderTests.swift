//
//  DebuggableInterceptorProviderTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 5/31/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class DebuggableInterceptorProviderTests: XCTestCase {
    func testInterceptorsForOperation_withAnyGraphQLOperation() {
        let interceptorProvider = DebuggableInterceptorProvider(MockInterceptorProvider())
        let operation = AnyGraphQLOperation(MockGraphQLQuery())
        let interceptors = interceptorProvider.interceptors(for: operation)
        continueAfterFailure = false
        XCTAssertEqual(interceptors.count, 2)
        XCTAssert(interceptors[0] is DebugInitializeInterceptor)
        XCTAssert(interceptors[1] is DebuggableResultTranslateInterceptor)
    }

    func testInterceptorsForOperation_withoutAnyGraphQLOperation() {
        let interceptorProvider = DebuggableInterceptorProvider(MockInterceptorProvider())
        let operation = MockGraphQLQuery()
        let interceptors = interceptorProvider.interceptors(for: operation)
        continueAfterFailure = false
        XCTAssertEqual(interceptors.count, 1)
        XCTAssert(interceptors[0] is DebugInitializeInterceptor)
    }

    func testAdditionalErrorInterceptor() {
        let interceptorProvider = DebuggableInterceptorProvider(MockInterceptorProvider())
        let operation = MockGraphQLQuery()
        let interceptor = interceptorProvider.additionalErrorInterceptor(for: operation)
        XCTAssert(interceptor is MockErrorInterceptor)
    }

    func testInterceptorWillSendOperation() {
        let interceptorProvider = DebuggableInterceptorProvider(MockInterceptorProvider())
        let delegateHandler = DebuggableInterceptorProviderDelegateHandler()
        interceptorProvider.delegate = delegateHandler
        let interceptor = MockInterceptor()
        let operation = MockGraphQLQuery()
        let expectation = self.expectation(description: "interceptorProvider(willSendOperation:) delegate method should be called.")
        delegateHandler.willSendOperation = { receivedInterceptorProvider, receivedOperation in
            XCTAssert(receivedInterceptorProvider as AnyObject === interceptorProvider)
            XCTAssertEqual(receivedOperation.operationType, operation.operationType)
            XCTAssertEqual(receivedOperation.operationName, operation.operationName)
            XCTAssertEqual(receivedOperation.operationDefinition, operation.operationDefinition)
            XCTAssertEqual(receivedOperation.operationIdentifier, operation.operationIdentifier)
            expectation.fulfill()
        }
        interceptorProvider.interceptor(interceptor, willSendOperation: operation)
        waitForExpectations(timeout: 0.5)
    }

    func testInterceptorDidSendOperation() {
        let interceptorProvider = DebuggableInterceptorProvider(MockInterceptorProvider())
        let delegateHandler = DebuggableInterceptorProviderDelegateHandler()
        interceptorProvider.delegate = delegateHandler
        let interceptor = MockInterceptor()
        let operation = MockGraphQLQuery()
        let expectation = self.expectation(description: "interceptorProvider(didSendOperation:result:) delegate method should be called.")
        delegateHandler.didSendOperation = { receivedInterceptorProvider, receivedOperation, result in
            XCTAssert(receivedInterceptorProvider as AnyObject === interceptorProvider)
            XCTAssertEqual(receivedOperation.operationType, operation.operationType)
            XCTAssertEqual(receivedOperation.operationName, operation.operationName)
            XCTAssertEqual(receivedOperation.operationDefinition, operation.operationDefinition)
            XCTAssertEqual(receivedOperation.operationIdentifier, operation.operationIdentifier)
            XCTAssertNotNil(try? result.get())
            expectation.fulfill()
        }
        let graphQLResult = GraphQLResult(data: MockGraphQLQuery.Data(unsafeResultMap: [:]),
                                          extensions: nil,
                                          errors: nil,
                                          source: .server,
                                          dependentKeys: nil)
        interceptorProvider.interceptor(interceptor, didSendOperation: operation, result: .success(graphQLResult))
        waitForExpectations(timeout: 0.5)
    }
}

private class DebuggableInterceptorProviderDelegateHandler: DebuggableInterceptorProviderDelegate {
    var willSendOperation: ((InterceptorProvider, AnyGraphQLOperation) -> Void)?
    var didSendOperation: ((InterceptorProvider, AnyGraphQLOperation, Result<GraphQLResult<AnyGraphQLOperation.Data>, Error>) -> Void)?

    func interceptorProvider<Operation>(_ interceptorProvider: InterceptorProvider, willSendOperation operation: Operation) where Operation : GraphQLOperation {
        willSendOperation?(interceptorProvider, AnyGraphQLOperation(operation))
    }

    func interceptorProvider<Operation>(_ interceptorProvider: InterceptorProvider, didSendOperation operation: Operation, result: Result<GraphQLResult<Operation.Data>, Error>) where Operation : GraphQLOperation {
        didSendOperation?(interceptorProvider, AnyGraphQLOperation(operation), result.map(GraphQLResult.init(_:)))
    }
}

private class MockInterceptorProvider: InterceptorProvider {
    func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation : GraphQLOperation {
        return []
    }

    func additionalErrorInterceptor<Operation>(for operation: Operation) -> ApolloErrorInterceptor? where Operation : GraphQLOperation {
        return MockErrorInterceptor()
    }
}

private class MockInterceptor: ApolloInterceptor {
    func interceptAsync<Operation>(chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation : GraphQLOperation {
        // Do nothing.
    }
}

private class MockErrorInterceptor: ApolloErrorInterceptor {
    func handleErrorAsync<Operation>(error: Error, chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation : GraphQLOperation {
        // Do nothing.
    }
}
