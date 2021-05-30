//
//  DebuggableInterceptorProvider.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 5/30/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

protocol DebuggableInterceptorProviderDelegate: class {
    func interceptorProvider<Operation>(_ interceptorProvider: InterceptorProvider, willSendOperation operation: Operation) where Operation: GraphQLOperation
    func interceptorProvider<Operation>(_ interceptorProvider: InterceptorProvider, didSendOperation operation: Operation, result: Result<GraphQLResult<Operation.Data>, Error>) where Operation: GraphQLOperation
}

public class DebuggableInterceptorProvider: InterceptorProvider {
    weak var delegate: DebuggableInterceptorProviderDelegate?
    private let interceptorProvider: InterceptorProvider
    private let debugInitializeInterceptor: DebugInitializeInterceptor
    private let debuggableResultTranslateInterceptor = DebuggableResultTranslateInterceptor()

    public init(_ interceptorProvider: InterceptorProvider) {
        self.interceptorProvider = interceptorProvider
        debugInitializeInterceptor = DebugInitializeInterceptor()
        debugInitializeInterceptor.delegate = self
    }

    public func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation : GraphQLOperation {
        var interceptors = interceptorProvider.interceptors(for: operation)
        interceptors.insert(debugInitializeInterceptor, at: 0)
        if operation is AnyGraphQLOperation {
            interceptors.append(debuggableResultTranslateInterceptor)
        }
        return interceptors
    }

    public func additionalErrorInterceptor<Operation: GraphQLOperation>(for operation: Operation) -> ApolloErrorInterceptor? {
        return interceptorProvider.additionalErrorInterceptor(for: operation)
    }
}

extension DebuggableInterceptorProvider: DebugInitializeInterceptorDelegate {
    func interceptor<Operation>(_ interceptor: DebugInitializeInterceptor, willSendOperation operation: Operation) where Operation : GraphQLOperation {
        delegate?.interceptorProvider(self, willSendOperation: operation)
    }

    func interceptor<Operation>(_ interceptor: DebugInitializeInterceptor, didSendOperation operation: Operation, result: Result<GraphQLResult<Operation.Data>, Error>) where Operation : GraphQLOperation {
        delegate?.interceptorProvider(self, didSendOperation: operation, result: result)
    }
}
