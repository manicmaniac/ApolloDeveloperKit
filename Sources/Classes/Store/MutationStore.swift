//
//  MutationStore.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/16/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

/**
 * `MutationStoreValue` represents a cache record of the mutation.
 *
 * This class is Swift implementation of `apollo-client`'s `MutationStoreValue`.
 */
struct MutationStoreValue {
    let mutation: String
    let variables: GraphQLMap?
    fileprivate(set) var loading: Bool
    fileprivate(set) var error: Error?
}

// MARK: JSONEncodable

extension MutationStoreValue: JSONEncodable {
    var jsonValue: JSONValue {
        return [
            "mutation": mutation,
            "variables": variables.jsonValue,
            "loading": loading,
            "error": error.flatMap { JSError($0) }.jsonValue
        ]
    }
}

/**
 * `MutationStore` is the class to save mutations and their states.
 *
 * This class is Swift implementation of `apollo-client`'s `MutationStore`.
 * Any methods in this class are thread-unsafe.
 *
 * - SeeAlso: https://github.com/apollographql/apollo-client/blob/master/packages/apollo-client/src/data/mutations.ts
 */
class MutationStore {
    private(set) var store = [MutationStoreValue]()

    func get(mutationId: Int) -> MutationStoreValue? {
        return store[mutationId]
    }

    func initMutation<Operation: GraphQLOperation>(mutation: Operation) {
        let value = MutationStoreValue(mutation: mutation.queryDocument,
                                       variables: mutation.variables,
                                       loading: true,
                                       error: nil)
        store.append(value)
    }

    func markMutationError(mutationId: Int, error: Error) {
        store[mutationId].loading = false
        store[mutationId].error = error
    }

    func markMutationResult(mutationId: Int) {
        store[mutationId].loading = false
        store[mutationId].error = nil
    }
}
