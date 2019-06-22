//
//  MutationStore.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/16/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

struct MutationStoreValue: JSONEncodable {
    let mutation: String
    let variables: GraphQLMap?
    var loading: Bool
    var error: Error?

    var jsonValue: JSONValue {
        return [
            "mutation": mutation,
            "variables": variables.jsonValue,
            "loading": loading,
            "error": error.flatMap(JSError.init(error:)).jsonValue
        ]
    }
}

class MutationStore {
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
