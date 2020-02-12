//
//  MockGraphQLOperations.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/12/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo
@testable import ApolloDeveloperKit

class MockGraphQLQuery: GraphQLQuery {
    typealias Data = AnyGraphQLSelectionSet

    let operationDefinition = ""
    let operationIdentifier = ""
    let operationName = ""
}

class MockGraphQLMutation: GraphQLMutation {
    typealias Data = AnyGraphQLSelectionSet

    let operationDefinition = ""
    let operationIdentifier = ""
    let operationName = ""
}

class MockGraphQLSubscription: GraphQLSubscription {
    typealias Data = AnyGraphQLSelectionSet

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
