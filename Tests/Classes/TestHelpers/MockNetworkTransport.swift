//
//  MockNetworkTransport.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 2/13/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo

class MockNetworkTransport: NetworkTransport {
    var clientName = "clientName"
    var clientVersion = "clientVersion"

    private var results = ArraySlice<Result<Any, Error>>()

    var isResultsEmpty: Bool {
        return results.isEmpty
    }

    func append<Data>(response: GraphQLResponse<Data>) where Data: GraphQLSelectionSet {
        results.append(.success(response))
    }

    func append(error: Error) {
        results.append(.failure(error))
    }

    func send<Operation>(operation: Operation, cachePolicy: CachePolicy, contextIdentifier: UUID?, callbackQueue: DispatchQueue, completionHandler: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void) -> Cancellable where Operation : GraphQLOperation {
        let result = results.popFirst()
        switch result {
        case .success(let graphQLResult as GraphQLResult<Operation.Data>)?:
            completionHandler(.success(graphQLResult))
        case .failure(let error)?:
            completionHandler(.failure(error))
        case .success:
            fatalError("The type of the next response doesn't match the expected type.")
        case nil:
            fatalError("The number of invocation of send(operation:completionHandler:) exceeds the number of results.")
        }
        return MockCancellable()
    }
}

class MockCancellable: Cancellable {
    func cancel() {
        // do nothing
    }
}
