//
//  DebuggableResultTranslateInterceptor.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 5/30/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

/**
 * `DebuggableResultTranslateInterceptor` is an interceptor that translates legacy response to GraphQLResult.
 *
 * Since Apollo 0.34.0, Apollo parses returned raw GraphQL response along `GraphQLSelectionSet.selections` in `LegacyParsingInterceptor.interceptAsync(chain:request:response:completion:)` and store the result in `HTTPResponse.parsedResponse`.
 * This change makes it difficult to query an arbitrary operation because `GraphQLSelectionSet.selections` cannot change its return value at runtime.
 *
 * However, at least for the time being we can use `HTTPResponse.legacyResponse`, which doesn't check `GraphQLSelectionSet.selections` instead of `HTTPResponse.parsedResponse`.
 *
 * `DebuggableResultTranslateInterceptor` is intended to be put after `LegacyParsingInterceptor` and it substitutes `HTTPResponse.legacyResponse` for `HTTPResponse.parsedResponse`, only when the operation comes from `ApolloDeveloperKit`.
 *
 * Typically you don't need to use this class directly but if you want to assemble your custom interceptor chain, you need to put this class at the right place.
 */
public class DebuggableResultTranslateInterceptor: ApolloInterceptor {
    public enum DebuggableResultTranslateError: Error, LocalizedError {
        /**
         * Indicates a logic error that is caused by putting `DebuggableResultTranslateInterceptor` before parsing a response.
         */
        case noResponseToTranslate

        public var errorDescription: String? {
            switch self {
            case .noResponseToTranslate:
                return "The Debuggable Result Translate Interceptor was called before a response was received to be parsed. Double-check the order of your interceptors."
            }
        }
    }

    public func interceptAsync<Operation>(chain: RequestChain, request: HTTPRequest<Operation>, response: HTTPResponse<Operation>?, completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) where Operation: GraphQLOperation {
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
