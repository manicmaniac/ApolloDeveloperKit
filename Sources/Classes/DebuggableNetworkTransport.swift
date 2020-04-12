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
        // `clientName` and `clientVersion` have been introduced since Apollo 0.19.0.
        // To keep backward compatibility, we have to use reflection to get the underlying `networkTransport`'s properties.
        // As for before Apollo 0.19.0 these properties haven't been used so they will be an empty string.
        let children = Mirror(reflecting: networkTransport).children
        self.clientName = children.first { $0.label == "clientName" }?.value as? String ?? ""
        self.clientVersion = children.first { $0.label == "clientVersion" }?.value as? String ?? ""
    }
}

// MARK: NetworkTransport

extension DebuggableNetworkTransport: NetworkTransport {
    public func send<Operation>(operation: Operation, completionHandler: @escaping (Swift.Result<GraphQLResponse<Operation.Data>, Error>) -> Void) -> Cancellable where Operation: GraphQLOperation {
        delegate?.networkTransport(self, willSendOperation: operation)
        return networkTransport.send(operation: operation) { [weak self] result in
            if let self = self {
                self.delegate?.networkTransport(self, didSendOperation: operation, result: result)
            }
            completionHandler(result)
        }
    }
}
