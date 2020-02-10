//
//  OperationStoreController.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/10/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo

final class OperationStoreController {
    private(set) var store: OperationStore
    private let queue = DispatchQueue(label: "com.github.manicmaniac.ApolloDeveloperKit.OperationStoreController")

    init(store: OperationStore) {
        self.store = store
    }
}

extension OperationStoreController: DebuggableNetworkTransportDelegate {
    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation) where Operation : GraphQLOperation {
        queue.async(flags: .barrier) { [weak self] in
            self?.store.add(operation)
        }
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, response: GraphQLResponse<Operation>?, error: Error?) where Operation : GraphQLOperation {
        queue.async(flags: .barrier) { [weak self] in
            if let error = error {
                self?.store.setFailure(for: operation, networkError: error)
            } else {
                let graphQLErrors = (response?.body["errors"] as? [JSONObject])?.map(GraphQLError.init(_:)) ?? []
                self?.store.setSuccess(for: operation, graphQLErrors: graphQLErrors)
            }
        }
    }
}
