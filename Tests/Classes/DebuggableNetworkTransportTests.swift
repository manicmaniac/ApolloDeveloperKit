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
    func testSendOperationWithCompletionHandler() {
        let operation = MockGraphQLQuery()
        XCTContext.runActivity(named: "when response is not nil but error is nil") { _ in
            let response = GraphQLResponse<MockGraphQLQuery>(operation: operation, body: ["foo": "bar"])
            let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport(response: response, error: nil))
            let expectation = self.expectation(description: "completionHandler should be called")
            let cancellable = networkTransport.send(operation: operation) { response, error in
                XCTAssertNotNil(response)
                XCTAssertEqual(response?.body.count, 1)
                XCTAssertNil(error)
                expectation.fulfill()
            }
            XCTAssertTrue(cancellable is MockCancellable)
            waitForExpectations(timeout: 0.25, handler: nil)
        }
        XCTContext.runActivity(named: "when response is nil and error is not nil") { _ in
            let response: GraphQLResponse<MockGraphQLQuery>? = nil
            let urlError = URLError(.badURL)
            let networkTransport = DebuggableNetworkTransport(networkTransport: MockNetworkTransport(response: response, error: urlError))
            let expectation = self.expectation(description: "completionHandler should be called")
            let cancellable = networkTransport.send(operation: operation) { response, error in
                XCTAssertNil(response)
                XCTAssertTrue(error as NSError? === urlError as NSError)
                expectation.fulfill()
            }
            XCTAssertTrue(cancellable is MockCancellable)
            waitForExpectations(timeout: 0.25, handler: nil)
        }
    }
}

class MockNetworkTransport: NetworkTransport {
    private let response: Any?
    private let error: Error?

    init<Operation>(response: GraphQLResponse<Operation>?, error: Error?) where Operation : GraphQLOperation {
        self.response = response
        self.error = error
    }

    func send<Operation>(operation: Operation, completionHandler: @escaping (GraphQLResponse<Operation>?, Error?) -> Void) -> Cancellable where Operation : GraphQLOperation {
        completionHandler(response as? GraphQLResponse<Operation>, error)
        return MockCancellable()
    }
}

class MockCancellable: Cancellable {
    func cancel() {
        // do nothing
    }
}

class MockGraphQLQuery: GraphQLQuery {
    typealias Data = MockGraphQLSelectionSet

    let operationDefinition = ""
    let operationIdentifier = ""
    let operationName = ""
}

class MockGraphQLSelectionSet: GraphQLSelectionSet {
    static let selections = [GraphQLSelection]()
    let resultMap: ResultMap

    required init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
    }
}
