//
//  DebugInitializeInterceptorTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 5/31/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class DebugInitializeInterceptorTests: XCTestCase {
    func testInterceptAsync() {
        let interceptor = DebugInitializeInterceptor()
        let delegateHandler = DebugInitializeInterceptorDelegateHandler()
        interceptor.delegate = delegateHandler
        let operation = MockGraphQLQuery()
        let chain = RequestChain(interceptors: [])
        let url = URL(string: "https://localhost/graphql")!
        let request = HTTPRequest<MockGraphQLQuery>(graphQLEndpoint: url,
                                                    operation: operation,
                                                    contentType: "",
                                                    clientName: "",
                                                    clientVersion: "",
                                                    additionalHeaders: [:])
        let expectationForWillSendOperation = expectation(description: "interceptor(_:willSendOperation:) delegate method should be called.")
        var isInterceptorWillSendOperationCalled = false
        var isInterceptorDidSendOperationCalled = false
        delegateHandler.interceptorWillSendOperation = { receivedInterceptor, receivedOperation in
            isInterceptorWillSendOperationCalled = true
            XCTAssertFalse(isInterceptorDidSendOperationCalled)
            XCTAssert(receivedInterceptor === interceptor)
            XCTAssertEqual(receivedOperation.operationType, operation.operationType)
            XCTAssertEqual(receivedOperation.operationName, operation.operationName)
            XCTAssertEqual(receivedOperation.operationDefinition, operation.operationDefinition)
            XCTAssertEqual(receivedOperation.operationIdentifier, operation.operationIdentifier)
            expectationForWillSendOperation.fulfill()
        }
        let expectationForDidSendOperation = expectation(description: "interceptor(_:didSendOperation:result:) delegate method should be called.")
        delegateHandler.interceptorDidSendOperation = { receivedInterceptor, receivedOperation, receivedResult in
            isInterceptorDidSendOperationCalled = true
            XCTAssert(isInterceptorWillSendOperationCalled)
            XCTAssert(receivedInterceptor === interceptor)
            XCTAssertEqual(receivedOperation.operationType, operation.operationType)
            XCTAssertEqual(receivedOperation.operationName, operation.operationName)
            XCTAssertEqual(receivedOperation.operationDefinition, operation.operationDefinition)
            XCTAssertEqual(receivedOperation.operationIdentifier, operation.operationIdentifier)
            XCTAssertNil(try? receivedResult.get())
            expectationForDidSendOperation.fulfill()
        }
        let expectationForCompletion = expectation(description: "completion callback should be called.")
        interceptor.interceptAsync(chain: chain, request: request, response: nil) { result in
            XCTAssert(isInterceptorWillSendOperationCalled)
            XCTAssert(isInterceptorDidSendOperationCalled)
            expectationForCompletion.fulfill()
        }
        waitForExpectations(timeout: 0.5)
    }
}

class DebugInitializeInterceptorDelegateHandler: DebugInitializeInterceptorDelegate {
    var interceptorWillSendOperation: ((DebugInitializeInterceptor, AnyGraphQLOperation) -> Void)?
    var interceptorDidSendOperation: ((DebugInitializeInterceptor, AnyGraphQLOperation, Result<GraphQLResult<AnyGraphQLOperation.Data>, Error>) -> Void)?

    func interceptor<Operation>(_ interceptor: DebugInitializeInterceptor, willSendOperation operation: Operation) where Operation : GraphQLOperation {
        interceptorWillSendOperation?(interceptor, AnyGraphQLOperation(operation))
    }

    func interceptor<Operation>(_ interceptor: DebugInitializeInterceptor, didSendOperation operation: Operation, result: Result<GraphQLResult<Operation.Data>, Error>) where Operation : GraphQLOperation {
        let typeErasedResult = result.map { (graphQLResult) -> GraphQLResult<AnyGraphQLOperation.Data> in
            return GraphQLResult(data: try? graphQLResult.data.flatMap(AnyGraphQLOperation.Data.init(_:)),
                                 extensions: graphQLResult.extensions,
                                 errors: graphQLResult.errors,
                                 source: .server,
                                 dependentKeys: nil)
        }
        interceptorDidSendOperation?(interceptor, AnyGraphQLOperation(operation), typeErasedResult)
    }
}
