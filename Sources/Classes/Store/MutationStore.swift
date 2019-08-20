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
public struct MutationStoreValue {
    let mutation: String
    let variables: GraphQLMap?
    var loading: Bool
    var error: Error?
}

// MARK: JSONEncodable

extension MutationStoreValue: JSONEncodable {
    public var jsonValue: JSONValue {
        return [
            "mutation": mutation,
            "variables": variables.jsonValue,
            "loading": loading,
            "error": error.flatMap(JSError.init(error:)).jsonValue
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
public class MutationStore {
    private(set) var store = [String: MutationStoreValue]()

    func get(mutationId: String) -> MutationStoreValue? {
        return store[mutationId]
    }

    func initMutation<Operation: GraphQLOperation>(mutationId: String, mutation: Operation) {
        store[mutationId] = MutationStoreValue(mutation: mutation.queryDocument,
                                               variables: mutation.variables,
                                               loading: true,
                                               error: nil)
    }

    func markMutationError(mutationId: String, error: Error) {
        store[mutationId]?.loading = false
        store[mutationId]?.error = error
    }

    func markMutationResult(mutationId: String) {
        store[mutationId]?.loading = false
        store[mutationId]?.error = nil
    }

    func reset() {
        store.removeAll()
    }
}
