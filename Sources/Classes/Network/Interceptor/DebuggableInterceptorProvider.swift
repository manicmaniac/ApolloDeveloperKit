//
//  DebuggableInterceptorProvider.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 5/30/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

public class DebuggableInterceptorProvider: InterceptorProvider {
    private let interceptorProvider: InterceptorProvider
    private let debuggableResultTranslateInterceptor = DebuggableResultTranslateInterceptor()

    public init(_ interceptorProvider: InterceptorProvider) {
        self.interceptorProvider = interceptorProvider
    }

    public func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation : GraphQLOperation {
        if operation is AnyGraphQLOperation {
            return interceptorProvider.interceptors(for: operation) + [debuggableResultTranslateInterceptor]
        } else {
            return interceptorProvider.interceptors(for: operation)
        }
    }

    public func additionalErrorInterceptor<Operation: GraphQLOperation>(for operation: Operation) -> ApolloErrorInterceptor? {
        return interceptorProvider.additionalErrorInterceptor(for: operation)
    }
}
