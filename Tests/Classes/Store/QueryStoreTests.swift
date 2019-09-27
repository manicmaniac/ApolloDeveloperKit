//
//  QueryStoreTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class QueryStoreTests: XCTestCase {
    let queryId = "1"
    let operationDefinition = """
        query AllPosts {
          posts {
            __typename
            ...PostDetails
          }
        }

        fragment PostDetails on Post {
          __typename
          id
          title
          votes
          author {
            __typename
            firstName
            lastName
          }
        }
        """

    func testInitQuery() {
        let store = QueryStore()
        let query = MockQuery(operationDefinition: operationDefinition)
        store.initQuery(queryId: queryId, query: query)
        let value = store.get(queryId: queryId)
        XCTAssertEqual(value?.document, query.queryDocument)
        XCTAssertNil(value?.variables)
        XCTAssertNil(value?.previousVariables)
        XCTAssertNil(value?.networkError)
        XCTAssertEqual(value?.graphQLErrors.isEmpty, true)
    }

    func testMarkQueryResult() {
        let store = QueryStore()
        let query = MockQuery(operationDefinition: operationDefinition)
        store.initQuery(queryId: queryId, query: query)
        store.markQueryResult(queryId: queryId, graphQLErrors: [GraphQLError(["error": "some error"])])
        let value = store.get(queryId: queryId)
        XCTAssertEqual(value?.document, query.queryDocument)
        XCTAssertNil(value?.variables)
        XCTAssertNil(value?.previousVariables)
        XCTAssertNil(value?.networkError)
        XCTAssertEqual(value?.graphQLErrors.count, 1)
    }

    func testMarkQueryError() {
        let store = QueryStore()
        let query = MockQuery(operationDefinition: operationDefinition)
        store.initQuery(queryId: queryId, query: query)
        store.markQueryError(queryId: queryId, error: URLError(.badURL))
        let value = store.get(queryId: queryId)
        XCTAssertEqual(value?.document, query.queryDocument)
        XCTAssertNil(value?.variables)
        XCTAssertNil(value?.previousVariables)
        XCTAssertEqual(value?.networkError as NSError?, URLError(.badURL) as NSError)
        XCTAssertEqual(value?.graphQLErrors.isEmpty, true)
    }

    func testMarkQueryResultClient() {
        let store = QueryStore()
        let query = MockQuery(operationDefinition: operationDefinition)
        store.initQuery(queryId: queryId, query: query)
        store.markQueryError(queryId: queryId, error: URLError(.badURL))
        store.markQueryResultClient(queryId: queryId)
        let value = store.get(queryId: queryId)
        XCTAssertEqual(value?.document, query.queryDocument)
        XCTAssertNil(value?.variables)
        XCTAssertNil(value?.previousVariables)
        XCTAssertNil(value?.networkError)
        XCTAssertEqual(value?.graphQLErrors.isEmpty, true)
    }

    func testStopQuery() {
        let store = QueryStore()
        let query = MockQuery(operationDefinition: operationDefinition)
        store.initQuery(queryId: queryId, query: query)
        store.stopQuery(queryId: queryId)
        let value = store.get(queryId: queryId)
        XCTAssertNil(value)
    }

    func testReset() {
        let store = QueryStore()
        let query = MockQuery(operationDefinition: operationDefinition)
        store.initQuery(queryId: queryId, query: query)
        store.reset(observableQueryIds: [queryId])
        let value = store.get(queryId: queryId)
        XCTAssertNil(value)
    }
}

private class MockQuery: GraphQLQuery {
    typealias Data = AnyGraphQLSelectionSet

    let operationDefinition: String
    let operationIdentifier = ""
    let operationName = ""

    init(operationDefinition: String) {
        self.operationDefinition = operationDefinition
    }
}
