//
//  OperationStoreController.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/10/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo
import Dispatch

/**
 * `OperationStoreController` is a controller class of `OperationStore`.
 *
 * It owns a `OperationStore` and manipulates the store in a thread-safe manner, delegating `DebuggableNetworkTransport`.
 */
final class OperationStoreController {
    /**
     * A queue where operations perform.
     *
     * This property is only visible for testing purpose.
     */
    let queue = DispatchQueue(label: "com.github.manicmaniac.ApolloDeveloperKit.OperationStoreController")
    private(set) var store: OperationStore

    init(store: OperationStore) {
        self.store = store
    }
}

// MARK: DebuggableNetworkTransportDelegate

extension OperationStoreController: DebuggableNetworkTransportDelegate {
    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation) where Operation: GraphQLOperation {
        queue.async(flags: .barrier) { [weak self] in
            self?.store.add(operation)
        }
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, result: Result<GraphQLResponse<Operation.Data>, Error>) where Operation: GraphQLOperation {
        queue.async(flags: .barrier) { [weak self] in
            switch result {
            case .success(let response):
                let graphQLErrors = (response.body["errors"] as? [JSONObject])?.map(GraphQLError.init(_:)) ?? []
                self?.store.setSuccess(for: operation, graphQLErrors: graphQLErrors)
            case .failure(let error):
                self?.store.setFailure(for: operation, networkError: error)
            }
        }
    }
}
