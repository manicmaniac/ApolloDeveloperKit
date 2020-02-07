//
//  MutationStoreTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class MutationStoreValueTests: XCTestCase {
    func testJSONValue() {
        let mutationStoreValue = MutationStoreValue(mutation: "UpvotePost", variables: ["postId": 42], loading: false, error: URLError(.badURL))
        guard let jsonObject = mutationStoreValue.jsonValue as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(jsonObject["mutation"] as? String, "UpvotePost")
        XCTAssertEqual(jsonObject["loading"] as? Bool, false)

        XCTAssertEqual(jsonObject["variables"] as? NSDictionary, ["postId": 42])
        guard let error = jsonObject["error"] as? [String: Any] else {
            return XCTFail()
        }
        XCTAssertEqual(error["message"] as? String, URLError(.badURL).localizedDescription)
        XCTAssertNotNil(error["lineNumber"] as? Int)
        XCTAssertNotNil(error["fileName"] as? String)
    }
}

class MutationStoreTests: XCTestCase {
    let operationDefinition = """
        mutation UpvotePost($postId: Int!) {
          upvotePost(postId: $postId) {
            __typename
            id
            votes
          }
        }
        """

    func testInitMutation() {
        let store = MutationStore()
        let mutation = MockMutation(operationDefinition: operationDefinition)
        store.initMutation(mutationId: "foo", mutation: mutation)
        let value = store.get(mutationId: "foo")
        XCTAssertEqual(value?.mutation, mutation.queryDocument)
        XCTAssertEqual(value?.loading, true)
        XCTAssertNil(value?.error)
    }

    func testMarkMutationError() {
        let store = MutationStore()
        let mutation = MockMutation(operationDefinition: operationDefinition)
        store.initMutation(mutationId: "foo", mutation: mutation)
        store.markMutationError(mutationId: "foo", error: URLError(.badURL))
        let value = store.get(mutationId: "foo")
        XCTAssertEqual(value?.mutation, mutation.queryDocument)
        XCTAssertEqual(value?.loading, false)
        XCTAssertNotNil(value?.error)
    }

    func testMarkMutationResult() {
        let store = MutationStore()
        let mutation = MockMutation(operationDefinition: operationDefinition)
        store.initMutation(mutationId: "foo", mutation: mutation)
        store.markMutationResult(mutationId: "foo")
        let value = store.get(mutationId: "foo")
        XCTAssertEqual(value?.mutation, mutation.queryDocument)
        XCTAssertEqual(value?.loading, false)
        XCTAssertNil(value?.error)
    }
}

private class MockMutation: GraphQLMutation {
    typealias Data = AnyGraphQLSelectionSet

    let operationDefinition: String
    let operationIdentifier = ""
    let operationName = ""

    init(operationDefinition: String) {
        self.operationDefinition = operationDefinition
    }
}
