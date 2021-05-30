//
//  DebuggableResultTranslateInterceptor.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 5/30/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

public class DebuggableResultTranslateInterceptor: ApolloInterceptor {
    public enum DebuggableResultTranslateError: Error, LocalizedError {
        case noResponseToTranslate

        public var errorDescription: String? {
            switch self {
            case .noResponseToTranslate:
                return "The Debuggable Result Translate Interceptor was called before a response was received to be parsed. Double-check the order of your interceptors."
            }
        }
    }

    public func interceptAsync<Operation>(chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation : GraphQLOperation {
        guard request.operation is AnyGraphQLOperation else {
            return chain.proceedAsync(request: request, response: response, completion: completion)
        }
        guard let createdResponse = response, let parsedResponse = createdResponse.parsedResponse, let legacyResponse = createdResponse.legacyResponse else {
            return chain.handleErrorAsync(DebuggableResultTranslateError.noResponseToTranslate,
                                          request: request,
                                          response: response,
                                          completion: completion)
        }
        let data = AnyGraphQLSelectionSet(unsafeResultMap: legacyResponse.body)
        let result = GraphQLResult(data: data as? Operation.Data,
                                   extensions: parsedResponse.extensions,
                                   errors: parsedResponse.errors,
                                   source: parsedResponse.source,
                                   dependentKeys: nil)
        createdResponse.parsedResponse = result
        chain.proceedAsync(request: request, response: createdResponse, completion: completion)
    }
}
