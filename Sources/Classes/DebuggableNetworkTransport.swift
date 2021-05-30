//
//  DebuggableNetworkTransport.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/15/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

public protocol DebuggableNetworkTransportDelegate: class {
    func networkTransport<Operation: GraphQLOperation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation)
    func networkTransport<Operation: GraphQLOperation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, result: Result<GraphQLResult<Operation.Data>, Error>)
}

/**
 * `DebuggableNetworkTransport` is a bridge between `ApolloDebugServer` and `ApolloClient`.
 *
 * You should instantiate both `ApolloDebugServer` and `ApolloClient` with the same instance of this class.
 */
public protocol DebuggableNetworkTransport: NetworkTransport {
    var delegate: DebuggableNetworkTransportDelegate? { get set }
}
