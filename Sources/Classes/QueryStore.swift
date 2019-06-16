//
//  QueryStore.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/16/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

struct QueryStoreValue: JSONEncodable {
    var document: String
    var variables: GraphQLMap?
    var previousVariables: GraphQLMap?
    var networkError: Error?
    var graphQLErrors: [Error]

    var jsonValue: JSONValue {
        return [
            "document": document,
            "variables": variables.jsonValue,
            "previousVariables": previousVariables.jsonValue,
            "networkError": networkError.flatMap(JSError.init(error:)).jsonValue,
            "graphQLErrors": graphQLErrors.map(JSError.init(error:)).jsonValue
        ]
    }
}

class QueryStore {
    private(set) var store = [String: QueryStoreValue]()

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

    func markQueryResultClient(queryId: String) {
        store[queryId]?.networkError = nil
        store[queryId]?.previousVariables = nil
    }

    func stopQuery(queryId: String) {
        store.removeValue(forKey: queryId)
    }

    func reset(observableQueryIds: [String]) {
        for queryId in store.keys {
            if observableQueryIds.contains(queryId) {
                stopQuery(queryId: queryId)
            }
        }
    }
}
