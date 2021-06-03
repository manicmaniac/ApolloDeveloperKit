//
//  MockGraphQLOperations.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 2/12/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo
@testable import ApolloDeveloperKit

class MockGraphQLQuery: GraphQLQuery {
    typealias Data = AnyGraphQLSelectionSet

    let operationDefinition = "query {}"
    let operationIdentifier = "MockGraphQLQuery 1"
    let operationName = "MockGraphQLQuery"
}

class MockGraphQLMutation: GraphQLMutation {
    typealias Data = AnyGraphQLSelectionSet

    let operationDefinition = "mutation {}"
    let operationIdentifier = "MockGraphQLMutation 1"
    let operationName = "MockGraphQLMutation"
}

class MockGraphQLSubscription: GraphQLSubscription {
    typealias Data = AnyGraphQLSelectionSet

    let operationDefinition = "subscription {}"
    let operationIdentifier = "MockGraphQLSubscription 1"
    let operationName = "MockGraphQLSubscription"
}

class MockGraphQLSelectionSet: GraphQLSelectionSet {
    static let selections = [GraphQLSelection]()
    let resultMap: ResultMap

    required init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
    }
}
