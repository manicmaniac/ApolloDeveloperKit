//
//  QueryManager.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/16/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

class QueryManager: DebuggableNetworkTransportDelegate {
    let mutationStore = MutationStore()
    let queryStore = QueryStore()
    private var queries = [String: AnyObject]()
    private let operationQueue = OperationQueue()
    private var counter = 0

    private func generateQueryId() -> String {
        counter += 1
        return String(describing: counter)
    }

    // MARK: - DebuggableHTTPNetworkTransportDelegate

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation) where Operation : GraphQLOperation {
        operationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            let queryId = self.generateQueryId()
            switch operation.operationType {
            case .query:
                self.queries[queryId] = operation
                self.queryStore.initQuery(queryId: queryId, query: operation)
            case .mutation:
                self.queries[queryId] = operation
                self.mutationStore.initMutation(mutationId: queryId, mutation: operation)
            case .subscription:
                // TODO
                break
            }
        }
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, response: GraphQLResponse<Operation>?, error: Error?) where Operation : GraphQLOperation {
        operationQueue.addOperation { [weak self] in
            guard let self = self else { return }
            guard let queryId = self.queries.first(where: { key, value in value === operation })?.key else { return }
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
                // TODO
                break
            }
        }
    }
}
