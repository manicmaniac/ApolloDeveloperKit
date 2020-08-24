//
//  InMemoryOperationStore.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/10/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

/**
 * `InMemoryOperationStore` stores queries and mutations in memory.
 *
 * The current implementation stores queries and mutations respectively in an ordered dictionary.
 * Since Swift doesn't have a data structure like a mutable ordered dictionary, it is implemented with separate arrays,
 * one of which stores keys and the other stores values.
 *
 * The design is strongly inspired by `QueryStore` and `MutationStore` of `apollo-client`.
 *
 * - Warning: All operations are thread-unsafe.
 * - SeeAlso:
 * [queries.ts](https://github.com/apollographql/apollo-client/blob/v2.6.8/packages/apollo-client/src/data/queries.ts)
 * [mutations.ts](https://github.com/apollographql/apollo-client/blob/v2.6.8/packages/apollo-client/src/data/mutations.ts)]
 */
struct InMemoryOperationStore: OperationStore {
    private var queries = KeyedStack<ObjectIdentifier, OperationStoreValue>()
    private var mutations = KeyedStack<ObjectIdentifier, OperationStoreValue>()

    var state: State {
        let mutations = self.mutations.map { _, mutation in
            Mutation(error: mutation.networkError.flatMap(ErrorLike.init(error:)),
                     loading: mutation.isLoading,
                     mutation: mutation.queryDocument,
                     variables: mutation.variables)
        }
        let queries = self.queries.map { _, query in
            Query(document: query.queryDocument,
                  graphQLErrors: query.graphQLErrors?.map(ErrorLike.init(error:)),
                  networkError: query.networkError.flatMap(ErrorLike.init(error:)),
                  previousVariables: nil,
                  variables: query.variables)
        }
        return State(mutations: mutations, queries: queries)
    }

    mutating func add<Operation>(_ operation: Operation) where Operation: GraphQLOperation {
        switch operation.operationType {
        case .query:
            queries.push(OperationStoreValue(operation), for: ObjectIdentifier(operation))
        case .mutation:
            mutations.push(OperationStoreValue(operation), for: ObjectIdentifier(operation))
        case .subscription:
            break
        }
    }

    mutating func setFailure<Operation>(for operation: Operation, networkError: Error) where Operation: GraphQLOperation {
        switch operation.operationType {
        case .query:
            queries[ObjectIdentifier(operation)]?.state = .failure(networkError: networkError)
        case .mutation:
            mutations[ObjectIdentifier(operation)]?.state = .failure(networkError: networkError)
        case .subscription:
            break
        }
    }

    mutating func setSuccess<Operation>(for operation: Operation, graphQLErrors: [Error]) where Operation: GraphQLOperation {
        switch operation.operationType {
        case .query:
            queries[ObjectIdentifier(operation)]?.state = .success(graphQLErrors: graphQLErrors)
        case .mutation:
            mutations[ObjectIdentifier(operation)]?.state = .success(graphQLErrors: graphQLErrors)
        case .subscription:
            break
        }
    }
}

private struct OperationStoreValue {
    let queryDocument: String
    let variables: GraphQLMap?
    var state = OperationState.loading

    init<Operation>(_ operation: Operation) where Operation: GraphQLOperation {
        self.queryDocument = operation.queryDocument
        self.variables = operation.variables
    }

    var isLoading: Bool {
        if case .loading = state {
            return true
        }
        return false
    }

    var networkError: Error? {
        if case .failure(let networkError) = state {
            return networkError
        }
        return nil
    }

    var graphQLErrors: [Error]? {
        if case .success(let graphQLErrors) = state {
            return graphQLErrors
        }
        return nil
    }
}

private enum OperationState {
    case loading
    case failure(networkError: Error)
    case success(graphQLErrors: [Error])
}
