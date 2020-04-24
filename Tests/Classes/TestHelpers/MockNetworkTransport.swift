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

    private let response: Any?
    private let error: Error?

    init() {
        self.response = nil
        self.error = nil
    }

    init<Data>(response: GraphQLResponse<Data>?, error: Error?) where Data: GraphQLSelectionSet {
        self.response = response
        self.error = error
    }
    func send<Operation>(operation: Operation, completionHandler: @escaping (Result<GraphQLResponse<Operation.Data>, Error>) -> Void) -> Cancellable where Operation : GraphQLOperation {
        if let response = response as? GraphQLResponse<Operation.Data> {
            completionHandler(.success(response))
        } else if let error = error {
            completionHandler(.failure(error))
        } else {
            preconditionFailure("Either of response and error should exist")
        }
        return MockCancellable()
    }
}

class MockCancellable: Cancellable {
    func cancel() {
        // do nothing
    }
}
