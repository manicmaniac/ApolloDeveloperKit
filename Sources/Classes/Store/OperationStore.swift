//
//  OperationStore.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/10/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo

/**
 * `OperationStore` represents a data store for GraphQL operations.
 *
 * The interface is inspired by `QueryManager` of `apollo-client`.
 *
 * - SeeAlso:
 * [QueryManager.ts](https://github.com/apollographql/apollo-client/blob/v2.6.8/packages/apollo-client/src/core/QueryManager.ts)
 */
protocol OperationStore: class {
    var state: State { get }
    func add<Operation>(_ operation: Operation) where Operation: GraphQLOperation
    func setFailure<Operation>(for operation: Operation, networkError: Error) where Operation: GraphQLOperation
    func setSuccess<Operation>(for operation: Operation, graphQLErrors: [Error]) where Operation: GraphQLOperation
}
