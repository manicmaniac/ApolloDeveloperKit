//
//  QueryStore.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/16/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

/**
 * `QueryStoreValue` represents a cache record of the query.
 *
 * This class is Swift implementation of `apollo-client`'s `QueryStoreValue`.
 */
struct QueryStoreValue {
    let document: String
    let variables: GraphQLMap?
    fileprivate(set) var networkError: Error?
    fileprivate(set) var graphQLErrors: [Error]
}

// MARK: JSONEncodable

extension QueryStoreValue: JSONEncodable {
    var jsonValue: JSONValue {
        return [
            "document": document,
            "variables": variables.jsonValue,
            "previousVariables": NSNull(),
            "networkError": networkError.flatMap { JSError($0) }.jsonValue,
            "graphQLErrors": graphQLErrors.map { JSError($0) }.jsonValue
        ]
    }
}

/**
 * `QueryStore` is the class to save queries and their states.
 *
 * This class is Swift implementation of `apollo-client`'s `QueryStore`.
 * Any methods in this class are thread-unsafe.
 *
 * - SeeAlso: https://github.com/apollographql/apollo-client/blob/master/packages/apollo-client/src/data/queries.ts
 */
class QueryStore {
    private(set) var store = [QueryStoreValue]()

    func get(queryId: Int) -> QueryStoreValue? {
        return store[queryId]
    }

    func initQuery<Operation: GraphQLOperation>(query: Operation) {
        let value = QueryStoreValue(document: query.queryDocument,
                                    variables: query.variables,
                                    networkError: nil,
                                    graphQLErrors: [])
        store.append(value)
    }

    func markQueryResult(queryId: Int, graphQLErrors: [Error]?) {
        store[queryId].networkError = nil
        store[queryId].graphQLErrors = graphQLErrors ?? []
    }

    func markQueryError(queryId: Int, error: Error) {
        store[queryId].networkError = error
    }
}
