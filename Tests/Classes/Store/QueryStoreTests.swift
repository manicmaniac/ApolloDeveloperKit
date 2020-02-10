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

class QueryStoreValueTests: XCTestCase {
    func testJSONValue() {
        let queryStoreValue = QueryStoreValue(document: "query { post($id) { votes } }", variables: ["id": 42], networkError: URLError(.badURL), graphQLErrors: [])
        guard let jsonObject = queryStoreValue.jsonValue as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(jsonObject["document"] as? String, "query { post($id) { votes } }")
        XCTAssertEqual(jsonObject["variables"] as? NSDictionary, ["id": 42])

        XCTAssertEqual(jsonObject["previousVariables"] as? NSNull, NSNull())
        guard let networkError = jsonObject["networkError"] as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(networkError["message"] as? String, URLError(.badURL).localizedDescription)
        XCTAssertNotNil(networkError["lineNumber"] as? Int)
        XCTAssertNotNil(networkError["fileName"] as? String)
        XCTAssertEqual((jsonObject["graphQLErrors"] as? [Error])?.isEmpty, true)
    }
}

class QueryStoreTests: XCTestCase {
    let queryId = 1
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
        XCTAssertEqual(value?.networkError as NSError?, URLError(.badURL) as NSError)
        XCTAssertEqual(value?.graphQLErrors.isEmpty, true)
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
