//
//  QueryManager.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/16/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

/**
 * `QueryManager` is like a controller object which is responsible for saving each GraphQL operations.
 *
 * This class is Swift implementation of `apollo-client`'s `QueryManager`.
 *
 * - SeeAlso: https://github.com/apollographql/apollo-client/blob/master/packages/apollo-client/src/core/QueryManager.ts
 */
class QueryManager {
    let mutationStore = MutationStore()
    let queryStore = QueryStore()
    private var queries = [String: AnyObject]()
    private let queue = DispatchQueue(label: "com.github.manicmaniac.ApolloDeveloperKit.QueryManager")
    private var counter = 0

    private func generateQueryId() -> String {
        counter += 1
        return String(describing: counter)
    }
}

// MARK: DebuggableHTTPNetworkTransportDelegate

extension QueryManager: DebuggableNetworkTransportDelegate {
    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation) where Operation: GraphQLOperation {
        queue.sync(flags: .barrier) { [unowned self] in
            let queryId = self.generateQueryId()
            switch operation.operationType {
            case .query:
                self.queries[queryId] = operation
                self.queryStore.initQuery(queryId: queryId, query: operation)
            case .mutation:
                self.queries[queryId] = operation
                self.mutationStore.initMutation(mutationId: queryId, mutation: operation)
            case .subscription:
                break
            }
        }
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, response: GraphQLResponse<Operation>?, error: Error?) where Operation: GraphQLOperation {
        queue.sync(flags: .barrier) { [unowned self] in
            guard let queryId = self.queries.first(where: { _, value in value === operation })?.key else { return }
            switch (operation.operationType, error) {
            case (.query, nil):
                let graphQLErrors = (response?.body["errors"] as? [JSONObject])?.map(GraphQLError.init(_:))
                self.queryStore.markQueryResult(queryId: queryId, graphQLErrors: graphQLErrors)
            case (.query, let error?):
                self.queryStore.markQueryError(queryId: queryId, error: error)
            case (.mutation, nil):
                self.mutationStore.markMutationResult(mutationId: queryId)
            case (.mutation, let error?):
                self.mutationStore.markMutationError(mutationId: queryId, error: error)
            case (.subscription, _):
                break
            }
        }
    }
}
