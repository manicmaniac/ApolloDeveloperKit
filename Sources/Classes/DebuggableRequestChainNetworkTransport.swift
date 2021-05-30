//
//  DebuggableRequestChainNetworkTransport.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 5/30/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

open class DebuggableRequestChainNetworkTransport: RequestChainNetworkTransport, DebuggableNetworkTransport {
    public weak var delegate: DebuggableNetworkTransportDelegate?
    private let debuggableInterceptorProvider: DebuggableInterceptorProvider

    public override init(interceptorProvider: InterceptorProvider,
                         endpointURL: URL,
                         additionalHeaders: [String : String] = [:],
                         autoPersistQueries: Bool = false,
                         requestBodyCreator: RequestBodyCreator = ApolloRequestBodyCreator(),
                         useGETForQueries: Bool = false,
                         useGETForPersistedQueryRetry: Bool = false) {
        debuggableInterceptorProvider = DebuggableInterceptorProvider(interceptorProvider)
        super.init(interceptorProvider: debuggableInterceptorProvider,
                   endpointURL: endpointURL,
                   additionalHeaders: additionalHeaders,
                   autoPersistQueries: autoPersistQueries,
                   requestBodyCreator: requestBodyCreator,
                   useGETForQueries: useGETForQueries,
                   useGETForPersistedQueryRetry: useGETForPersistedQueryRetry)
        debuggableInterceptorProvider.delegate = self
    }
}

extension DebuggableRequestChainNetworkTransport: DebuggableInterceptorProviderDelegate {
    func interceptorProvider<Operation>(_ interceptorProvider: InterceptorProvider, willSendOperation operation: Operation) where Operation : GraphQLOperation {
        delegate?.networkTransport(self, willSendOperation: operation)
    }

    func interceptorProvider<Operation>(_ interceptorProvider: InterceptorProvider, didSendOperation operation: Operation, result: Result<GraphQLResult<Operation.Data>, Error>) where Operation : GraphQLOperation {
        delegate?.networkTransport(self, didSendOperation: operation, result: result)
    }
}
