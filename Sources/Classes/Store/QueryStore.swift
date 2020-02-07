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
    fileprivate(set) var previousVariables: GraphQLMap?
    fileprivate(set) var networkError: Error?
    fileprivate(set) var graphQLErrors: [Error]
}

// MARK: JSONEncodable

extension QueryStoreValue: JSONEncodable {
    var jsonValue: JSONValue {
        return [
            "document": document,
            "variables": variables.jsonValue,
            "previousVariables": previousVariables.jsonValue,
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
    private(set) var store = [String: QueryStoreValue]()

    func get(queryId: String) -> QueryStoreValue? {
        return store[queryId]
    }

    func initQuery<Operation: GraphQLOperation>(queryId: String, query: Operation) {
        let previousQuery = store[queryId]
        precondition(previousQuery == nil || previousQuery?.document == query.queryDocument,
                     "Internal Error: may not update existing query string in store")
        let value = QueryStoreValue(document: query.queryDocument,
                                    variables: query.variables,
                                    previousVariables: previousQuery?.variables,
                                    networkError: nil,
                                    graphQLErrors: previousQuery?.graphQLErrors ?? [])
        store[queryId] = value
    }

    func markQueryResult(queryId: String, graphQLErrors: [Error]?) {
        store[queryId]?.networkError = nil
        store[queryId]?.graphQLErrors = graphQLErrors ?? []
        store[queryId]?.previousVariables = nil
    }

    func markQueryError(queryId: String, error: Error) {
        store[queryId]?.networkError = error
    }
}
