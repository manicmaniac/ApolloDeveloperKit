//
//  NotifyStartInterceptor.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 5/30/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

protocol DebugInitializeInterceptorDelegate: class {
    func interceptor<Operation>(_ interceptor: ApolloInterceptor, willSendOperation operation: Operation) where Operation: GraphQLOperation
    func interceptor<Operation>(_ interceptor: ApolloInterceptor, didSendOperation operation: Operation, result: Result<GraphQLResult<Operation.Data>, Error>) where Operation: GraphQLOperation
}

public class DebugInitializeInterceptor: ApolloInterceptor {
    weak var delegate: DebugInitializeInterceptorDelegate?

    public func interceptAsync<Operation>(chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation : GraphQLOperation {
        delegate?.interceptor(self, willSendOperation: request.operation)
        chain.proceedAsync(request: request,
                           response: response) { [weak self] result in
            if let self = self {
                self.delegate?.interceptor(self, didSendOperation: request.operation, result: result)
            }
            completion(result)
        }
    }
}
