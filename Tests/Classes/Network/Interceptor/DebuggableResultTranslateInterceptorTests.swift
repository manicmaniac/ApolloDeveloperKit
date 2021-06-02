//
//  DebuggableResultTranslateInterceptorTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 5/31/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class DebuggableResultTranslateInterceptorTests: XCTestCase {
    private let url = URL(string: "https://localhost/graphql")!
    private var interceptor: DebuggableResultTranslateInterceptor!
    private var mockInterceptor: MockInterceptor!
    private var chain: RequestChain!

    override func setUp() {
        interceptor = DebuggableResultTranslateInterceptor()
        mockInterceptor = MockInterceptor()
        chain = RequestChain(interceptors: [interceptor, mockInterceptor])
    }

    func testInterceptAsync_whenOperationIsNotAnyGraphQLOperation() {
        let operation = MockGraphQLQuery()
        let request = HTTPRequest(graphQLEndpoint: url,
                                  operation: operation,
                                  contentType: "",
                                  clientName: "",
                                  clientVersion: "",
                                  additionalHeaders: [:])
        let expectation = self.expectation(description: "The next interceptor's interceptAsync(...) should be called.")
        mockInterceptor.intercept = { [weak self] receivedChain, receivedRequest, receivedResponse, _ in
            XCTAssert(receivedChain === self?.chain)
            XCTAssertEqual(receivedRequest.graphQLEndpoint, request.graphQLEndpoint)
            XCTAssertEqual(receivedRequest.cachePolicy, request.cachePolicy)
            XCTAssertEqual(receivedRequest.contextIdentifier, request.contextIdentifier)
            XCTAssertEqual(receivedRequest.additionalHeaders, request.additionalHeaders)
            XCTAssertNil(receivedResponse)
            expectation.fulfill()
        }
        interceptor.interceptAsync(chain: chain, request: request, response: nil) { result in
            // Do nothing.
        }
        waitForExpectations(timeout: 0.5)
    }

    func testInterceptAsyncIsAnyGraphQLOperationWithoutResponse() {
        let operation = AnyGraphQLOperation(MockGraphQLQuery())
        chain.additionalErrorHandler = mockInterceptor
        let request = HTTPRequest(graphQLEndpoint: url,
                                  operation: operation,
                                  contentType: "",
                                  clientName: "",
                                  clientVersion: "",
                                  additionalHeaders: [:])
        let expectation = self.expectation(description: "The next interceptor's interceptAsync(...) should be called.")
        mockInterceptor.handleError = { [weak self] error, receivedChain, receivedRequest, receivedResponse, _ in
            XCTAssert(receivedChain === self?.chain)
            XCTAssertEqual(receivedRequest.graphQLEndpoint, request.graphQLEndpoint)
            XCTAssertEqual(receivedRequest.cachePolicy, request.cachePolicy)
            XCTAssertEqual(receivedRequest.contextIdentifier, request.contextIdentifier)
            XCTAssertEqual(receivedRequest.additionalHeaders, request.additionalHeaders)
            XCTAssertNil(receivedResponse)
            expectation.fulfill()
        }
        interceptor.interceptAsync(chain: chain, request: request, response: nil) { result in
            // Do nothing.
        }
        waitForExpectations(timeout: 0.5)
    }

    func testInterceptAsyncIsAnyGraphQLOperationWithResponse() {
        let operation = AnyGraphQLOperation(MockGraphQLQuery())
        let request = HTTPRequest(graphQLEndpoint: url,
                                  operation: operation,
                                  contentType: "",
                                  clientName: "",
                                  clientVersion: "",
                                  additionalHeaders: [:])
        let httpURLResponse = HTTPURLResponse(url: url,
                                              statusCode: 200,
                                              httpVersion: nil,
                                              headerFields: [:])!
        let parsedResponse = GraphQLResult(data: AnyGraphQLOperation.Data(unsafeResultMap: [:]),
                                           extensions: nil,
                                           errors: nil,
                                           source: .server,
                                           dependentKeys: nil)
        let response = HTTPResponse<AnyGraphQLOperation>(response: httpURLResponse,
                                    rawData: Data(),
                                    parsedResponse: parsedResponse)
        response.legacyResponse = GraphQLResponse(operation: operation, body: [:])
        let expectation = self.expectation(description: "The next interceptor's interceptAsync(...) should be called.")
        mockInterceptor.intercept = { [weak self] receivedChain, receivedRequest, receivedResponse, _ in
            XCTAssert(receivedChain === self?.chain)
            XCTAssertEqual(receivedRequest.graphQLEndpoint, request.graphQLEndpoint)
            XCTAssertEqual(receivedRequest.cachePolicy, request.cachePolicy)
            XCTAssertEqual(receivedRequest.contextIdentifier, request.contextIdentifier)
            XCTAssertEqual(receivedRequest.additionalHeaders, request.additionalHeaders)
            XCTAssertEqual(receivedResponse?.httpResponse, httpURLResponse)
            XCTAssertNotNil(receivedResponse?.parsedResponse?.data)
            XCTAssertNotNil(receivedResponse)
            expectation.fulfill()
        }
        interceptor.interceptAsync(chain: chain, request: request, response: response) { result in
            // Do nothing.
        }
        waitForExpectations(timeout: 0.5)
    }
}

private class MockInterceptor: ApolloInterceptor, ApolloErrorInterceptor {
    var intercept: ((RequestChain, HTTPRequest<AnyGraphQLOperation>, HTTPResponse<AnyGraphQLOperation>?, (Result<GraphQLResult<AnyGraphQLOperation.Data>, Error>) -> Void) -> Void)?

    var handleError: ((Error, RequestChain, HTTPRequest<AnyGraphQLOperation>, HTTPResponse<AnyGraphQLOperation>?, (Result<GraphQLResult<AnyGraphQLOperation.Data>, Error>) -> Void) -> Void)?

    func interceptAsync<Operation>(chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation : GraphQLOperation {
        if let response = response, let parsedResponse = response.parsedResponse {
            let typeErasedParsedResponse = GraphQLResult(parsedResponse)
            let typeErasedResponse = HTTPResponse<AnyGraphQLOperation>(response: response.httpResponse,
                                                                       rawData: response.rawData,
                                                                       parsedResponse: typeErasedParsedResponse)
            intercept?(chain, HTTPRequest(request), typeErasedResponse) { result in
                // Do nothing.
            }
        } else {
            intercept?(chain, HTTPRequest(request), nil) { result in
                // Do nothing.
            }
        }
    }

    func handleErrorAsync<Operation>(error: Error, chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation : GraphQLOperation {
        if let response = response, let parsedResponse = response.parsedResponse {
            let typeErasedParsedResponse = GraphQLResult(parsedResponse)
            let typeErasedResponse = HTTPResponse<AnyGraphQLOperation>(response: response.httpResponse,
                                                                       rawData: response.rawData,
                                                                       parsedResponse: typeErasedParsedResponse)
            handleError?(error, chain, HTTPRequest(request), typeErasedResponse) { result in
                // Do nothing.
            }
        } else {
            handleError?(error, chain, HTTPRequest(request), nil) { result in
                // Do nothing.
            }
        }
    }
}
