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

public final class DebuggableNetworkTransport: NetworkTransport {
    weak var delegate: DebuggableNetworkTransportDelegate?
    private let networkTransport: NetworkTransport

    public init(networkTransport: NetworkTransport) {
        self.networkTransport = networkTransport
    }

    public func send<Operation>(operation: Operation, completionHandler: @escaping (GraphQLResponse<Operation>?, Error?) -> Void) -> Cancellable where Operation : GraphQLOperation {
        delegate?.networkTransport(self, willSendOperation: operation)
        return networkTransport.send(operation: operation) { [weak self] response, error in
            if let self = self {
                self.delegate?.networkTransport(self, didSendOperation: operation, response: response, error: error)
            }
            completionHandler(response, error)
        }
    }
}
