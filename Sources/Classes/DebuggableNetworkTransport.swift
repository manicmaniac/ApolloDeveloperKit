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
        return Send<Operation>(networkTransport.send).call(operation) { [weak self] response, error in
            if let self = self {
                self.delegate?.networkTransport(self, didSendOperation: operation, response: response, error: error)
            }
            completionHandler(response, error)
        }
    }

    #if swift(>=5)
    public func send<Operation>(operation: Operation, completionHandler: @escaping (Result<GraphQLResponse<Operation>, Error>) -> Void) -> Cancellable where Operation: GraphQLOperation {
        delegate?.networkTransport(self, willSendOperation: operation)
        return Send<Operation>(networkTransport.send).call(operation) { [weak self] response, error in
            if let self = self {
                self.delegate?.networkTransport(self, didSendOperation: operation, response: response, error: error)
            }
            if let response = response {
                completionHandler(.success(response))
            } else if let error = error {
                completionHandler(.failure(error))
            } else {
                preconditionFailure("Either of response and error should exist")
            }
        }
    }
    #endif
}

/**
 * `Send` is a workaround to fill the gap between Apollo >= 0.13.0 and Apollo < 0.13.0.
 *
 * Apollo introduced a big breaking change around NetworkTransport,
 * that is to pass `Swift.Result` as the only argument of its callback instead of passing 2 optional values.
 * The change of callback's arity cannot be treated in a normal way.
 * So to have `ApolloDeveloperKit` work with both versions, I had to cheat Swift compiler with this enum.
 *
 * - SeeAlso: https://github.com/apollographql/apollo-ios/pull/644
 */
private enum Send<Operation: GraphQLOperation> {
    /**
     * The type of `NetworkTransport.send(operation:completionHandler:)` for Apollo < 0.13.0.
     */
    typealias Version1 = (Operation, @escaping (GraphQLResponse<Operation>?, Error?) -> Void) -> Cancellable

    case version1(Version1)

    init(_ function: @escaping Version1) {
        self = .version1(function)
    }

    #if swift(>=5)
    /**
     * The type of `NetworkTransport.send(operation:completionHandler:)` for Apollo >= 0.13.0.
     */
    typealias Version2 = (Operation, @escaping (Result<GraphQLResponse<Operation>, Error>) -> Void) -> Cancellable

    case version2(Version2)

    init(_ function: @escaping Version2) {
        self = .version2(function)
    }
    #endif

    var call: Version1 {
        return { operation, completionHandler in
            switch self {
            case .version1(let function):
                return function(operation, completionHandler)
            #if swift(>=5)
            case .version2(let function):
                return function(operation) { result in
                    switch result {
                    case .success(let response):
                        completionHandler(response, nil)
                    case .failure(let error):
                        completionHandler(nil, error)
                    }
                }
            #endif
            }
        }
    }
}
