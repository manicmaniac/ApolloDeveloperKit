//
//  DebuggableNetworkTransport.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/15/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

protocol DebuggableNetworkTransportDelegate: class {
    func networkTransport<Operation: GraphQLOperation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation)
    func networkTransport<Operation: GraphQLOperation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, response: GraphQLResponse<Operation>?, error: Error?)
}

/**
 * `DebuggableNetworkTransport` is a bridge between `ApolloDebugServer` and `ApolloClient`.
 *
 * You should instantiate both `ApolloDebugServer` and `ApolloClient` with the same instance of this class.
 */
public class DebuggableNetworkTransport {
    weak var delegate: DebuggableNetworkTransportDelegate?
    private let networkTransport: NetworkTransport

    /**
     * Initializes the receiver with the underlying network transport object.
     *
     * - Parameter networkTransport: The underlying network transport.
     */
    public init(networkTransport: NetworkTransport) {
        self.networkTransport = networkTransport
    }
}

// MARK: NetworkTransport

extension DebuggableNetworkTransport: NetworkTransport {
    public func send<Operation>(operation: Operation, completionHandler: @escaping (GraphQLResponse<Operation>?, Error?) -> Void) -> Cancellable where Operation: GraphQLOperation {
        delegate?.networkTransport(self, willSendOperation: operation)
        return networkTransport.send(operation: operation) { [weak self] response, error in
            if let self = self {
                self.delegate?.networkTransport(self, didSendOperation: operation, response: response, error: error)
            }
            completionHandler(response, error)
        }
    }
}
