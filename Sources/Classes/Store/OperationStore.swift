//
//  OperationStore.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/10/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo

protocol OperationStore: JSONEncodable {
    mutating func add<Operation>(_ operation: Operation) where Operation: GraphQLOperation
    mutating func setFailure<Operation>(for operation: Operation, networkError: Error) where Operation: GraphQLOperation
    mutating func setSuccess<Operation>(for operation: Operation, graphQLErrors: [Error]) where Operation: GraphQLOperation
}
