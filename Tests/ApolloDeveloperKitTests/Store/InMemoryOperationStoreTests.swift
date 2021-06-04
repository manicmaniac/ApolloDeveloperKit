//
//  InMemoryOperationStoreTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 2/12/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class InMemoryOperationStoreTests: XCTestCase {
    private var store: OperationStore!

    override func setUp() {
        store = InMemoryOperationStore()
    }

    func testAdd_withQuery() throws {
        let query = MockGraphQLQuery()
        store.add(query)
        XCTAssertEqual(store.state.jsonValue as? NSDictionary, [
            "queries": [
                [
                    "document": "query {}",
                    "variables": NSNull(),
                    "previousVariables": NSNull(),
                    "networkError": NSNull(),
                    "graphQLErrors": NSNull()
                ]
            ],
            "mutations": []
        ])
    }

    func testAdd_withMutation() {
        let mutation = MockGraphQLMutation()
        store.add(mutation)
        XCTAssertEqual(store.state.jsonValue as? NSDictionary, [
            "queries": [],
            "mutations": [
                [
                    "mutation": "mutation {}",
                    "variables": NSNull(),
                    "loading": true,
                    "error": NSNull(),
                ]
            ]
        ])
    }

    func testAdd_withSubscription() {
        let subscription = MockGraphQLSubscription()
        store.add(subscription)
        XCTAssertEqual(store.state.jsonValue as? NSDictionary, [
            "queries": [],
            "mutations": []
        ])
    }

    func testSetFailure_withQuery() {
        let query = MockGraphQLQuery()
        store.add(query)
        let error = URLError(.notConnectedToInternet)
        store.setFailure(for: query, networkError: error)
        let jsonObject = store.state.jsonValue as? [String: Any]
        let queries = jsonObject?["queries"] as? [[String: Any]]
        XCTAssertEqual(queries?.first?["document"] as? String, "query {}")
        XCTAssertTrue(queries?.first?["variables"] is NSNull)
        XCTAssertTrue(queries?.first?["previousVariables"] is NSNull)
        XCTAssertTrue(queries?.first?["graphQLErrors"] is NSNull)
        XCTAssertTrue(queries?.first?["networkError"] is [String: Any])
        XCTAssertEqual((jsonObject?["mutations"] as? NSArray)?.count, 0)
    }

    func testSetFailure_withMutation() {
        let query = MockGraphQLMutation()
        store.add(query)
        let error = URLError(.notConnectedToInternet)
        store.setFailure(for: query, networkError: error)
        let jsonObject = store.state.jsonValue as? [String: Any]
        let mutations = jsonObject?["mutations"] as? [[String: Any]]
        XCTAssertEqual(mutations?.first?["mutation"] as? String, "mutation {}")
        XCTAssertTrue(mutations?.first?["variables"] is NSNull)
        XCTAssertEqual(mutations?.first?["loading"] as? Bool, false)
        XCTAssertTrue(mutations?.first?["error"] is [String: Any])
    }

    func testSetFailure_withSubscription() {
        let subscription = MockGraphQLSubscription()
        store.add(subscription)
        let error = URLError(.notConnectedToInternet)
        store.setFailure(for: subscription, networkError: error)
        XCTAssertEqual(store.state.jsonValue as? NSDictionary, [
            "queries": [],
            "mutations": []
        ])
    }

    func testSetSuccess_withQuery_withoutErrors() {
        let query = MockGraphQLQuery()
        store.add(query)
        store.setSuccess(for: query, graphQLErrors: [])
        XCTAssertEqual(store.state.jsonValue as? NSDictionary, [
            "queries": [
                [
                    "document": "query {}",
                    "variables": NSNull(),
                    "previousVariables": NSNull(),
                    "networkError": NSNull(),
                    "graphQLErrors": []
                ]
            ],
            "mutations": []
        ])
    }

    func testSetSuccess_withQuery_withErrors() {
        let query = MockGraphQLQuery()
        store.add(query)
        let graphQLError = GraphQLError(["message": ""])
        store.setSuccess(for: query, graphQLErrors: [graphQLError])
        let jsonObject = store.state.jsonValue as? [String: Any]
        let queries = jsonObject?["queries"] as? [[String: Any]]
        XCTAssertEqual(queries?.first?["document"] as? String, "query {}")
        XCTAssertTrue(queries?.first?["variables"] is NSNull)
        XCTAssertTrue(queries?.first?["previousVariables"] is NSNull)
        let graphQLErrors = queries?.first?["graphQLErrors"] as? [[String: Any]]
        XCTAssertEqual(graphQLErrors?.first?["message"] as? String, "")
        XCTAssertTrue(queries?.first?["networkError"] is NSNull)
        XCTAssertEqual((jsonObject?["mutations"] as? NSArray)?.count, 0)
    }

    func testSetSuccess_withMutation_withoutErrors() {
        let mutation = MockGraphQLMutation()
        store.add(mutation)
        store.setSuccess(for: mutation, graphQLErrors: [])
        XCTAssertEqual(store.state.jsonValue as? NSDictionary, [
            "queries": [],
            "mutations": [
                [
                    "mutation": "mutation {}",
                    "variables": NSNull(),
                    "loading": false,
                    "error": NSNull(),
                ]
            ]
        ])
    }

    func testSetSuccess_withSubscription() {
        let subscription = MockGraphQLSubscription()
        store.add(subscription)
        store.setSuccess(for: subscription, graphQLErrors: [])
        XCTAssertEqual(store.state.jsonValue as? NSDictionary, [
            "queries": [],
            "mutations": []
        ])
    }
}
