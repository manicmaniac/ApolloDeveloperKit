//
//  OperationStore.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/10/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo

struct OperationStore {
    private var queryObjectIdentifiers = [ObjectIdentifier]()
    private var queries = [OperationStoreValue]()
    private var mutationObjectIdentifiers = [ObjectIdentifier]()
    private var mutations = [OperationStoreValue]()

    mutating func add<Operation>(_ operation: Operation) where Operation: GraphQLOperation {
        switch operation.operationType {
        case .query:
            queryObjectIdentifiers.append(ObjectIdentifier(operation))
            queries.append(OperationStoreValue(operation: operation))
        case .mutation:
            mutationObjectIdentifiers.append(ObjectIdentifier(operation))
            mutations.append(OperationStoreValue(operation: operation))
        case .subscription:
            break
        }
    }

    mutating func setFailure<Operation>(for operation: Operation, networkError: Error) where Operation: GraphQLOperation {
        switch operation.operationType {
        case .query:
            guard let index = queryObjectIdentifiers.lastIndex(of: ObjectIdentifier(operation)) else { return }
            queries[index].state = .failure(networkError: networkError)
        case .mutation:
            guard let index = mutationObjectIdentifiers.lastIndex(of: ObjectIdentifier(operation)) else { return }
            mutations[index].state = .failure(networkError: networkError)
        case .subscription:
            break
        }
    }

    mutating func setSuccess<Operation>(for operation: Operation, graphQLErrors: [Error]) where Operation: GraphQLOperation {
        switch operation.operationType {
        case .query:
            guard let index = queryObjectIdentifiers.lastIndex(of: ObjectIdentifier(operation)) else { return }
            queries[index].state = .success(graphQLErrors: graphQLErrors)
        case .mutation:
            guard let index = mutationObjectIdentifiers.lastIndex(of: ObjectIdentifier(operation)) else { return }
            mutations[index].state = .success(graphQLErrors: graphQLErrors)
        case .subscription:
            break
        }
    }
}

extension OperationStore: JSONEncodable {
    var jsonValue: JSONValue {
        return [
            "queries": queries.map { query in
                [
                    "document": query.queryDocument,
                    "variables": query.variables.jsonValue,
                    "previousVariables": NSNull(),
                    "networkError": query.networkError.flatMap { JSError($0) }.jsonValue,
                    "graphQLErrors": (query.graphQLErrors?.map { JSError($0) }).jsonValue
                ]
            },
            "mutations": mutations.map { mutation in
                [
                    "mutation": mutation.queryDocument,
                    "variables": mutation.variables.jsonValue,
                    "loading": mutation.isLoading,
                    "error": mutation.networkError.flatMap { JSError($0) }.jsonValue
                ]
            }
        ]
    }
}

private struct OperationStoreValue {
    let queryDocument: String
    let variables: GraphQLMap?
    var state = OperationState.loading

    init<Operation>(operation: Operation) where Operation: GraphQLOperation {
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
