//
//  QueryManager.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/16/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import Dispatch

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
    private var queries = [AnyObject]()
    private let queue = DispatchQueue(label: "com.github.manicmaniac.ApolloDeveloperKit.QueryManager")
}

// MARK: DebuggableHTTPNetworkTransportDelegate

extension QueryManager: DebuggableNetworkTransportDelegate {
    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation) where Operation: GraphQLOperation {
        queue.sync(flags: .barrier) { [unowned self] in
            switch operation.operationType {
            case .query:
                self.queries.append(operation)
                self.queryStore.initQuery(query: operation)
            case .mutation:
                self.queries.append(operation)
                self.mutationStore.initMutation(mutation: operation)
            case .subscription:
                break
            }
        }
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, response: GraphQLResponse<Operation>?, error: Error?) where Operation: GraphQLOperation {
        queue.sync(flags: .barrier) { [unowned self] in
            guard let queryId = self.queries.firstIndex(where: { value in value === operation }) else { return }
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
