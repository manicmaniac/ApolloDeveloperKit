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
    func networkTransport<Operation: GraphQLOperation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, result: Result<GraphQLResponse<Operation.Data>, Error>)
}

/**
 * `DebuggableNetworkTransport` is a bridge between `ApolloDebugServer` and `ApolloClient`.
 *
 * You should instantiate both `ApolloDebugServer` and `ApolloClient` with the same instance of this class.
 */
public class DebuggableNetworkTransport {
    public var clientName: String
    public var clientVersion: String
    weak var delegate: DebuggableNetworkTransportDelegate?
    private let networkTransport: NetworkTransport

    /**
     * Initializes the receiver with the underlying network transport object.
     *
     * - Parameter networkTransport: The underlying network transport.
     */
    public init(networkTransport: NetworkTransport) {
        self.networkTransport = networkTransport
        // Copies `clientName` and `clientVersion` in case someone wants to set
        // a different name or version from the original network transport.
        self.clientName = networkTransport.clientName
        self.clientVersion = networkTransport.clientVersion
    }
}

// MARK: NetworkTransport

extension DebuggableNetworkTransport: NetworkTransport {
    public func send<Operation>(operation: Operation, completionHandler: @escaping (Result<GraphQLResponse<Operation.Data>, Error>) -> Void) -> Cancellable where Operation: GraphQLOperation {
        delegate?.networkTransport(self, willSendOperation: operation)
        return networkTransport.send(operation: operation) { [weak self] result in
            if let self = self {
                self.delegate?.networkTransport(self, didSendOperation: operation, result: result)
            }
            completionHandler(result)
        }
    }
}
