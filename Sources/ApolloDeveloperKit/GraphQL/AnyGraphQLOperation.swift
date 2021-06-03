//
//  AnyGraphQLOperation.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/23/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

/**
 * `AnyGraphQLOperation` is the class representing any kind of GraphQL operation including query, mutation and subscription.
 */
final class AnyGraphQLOperation: GraphQLOperation {
    typealias Data = AnyGraphQLSelectionSet

    /**
     * The type of an actual operation.
     *
     * Always be a GraphQLOperationType.query even if it isn't a query.
     */
    let operationType: GraphQLOperationType

    /**
     * The query document of an operation.
     */
    let operationDefinition: String

    /**
     * The identifier of an operation.
     */
    let operationIdentifier: String?

    /**
     * The name of an operation.
     */
    let operationName: String

    /**
     * The query variables of an operation.
     */
    let variables: GraphQLMap?

    /**
     * Initializes a AnyGraphQLOperation object.
     *
     * Any kind of operation is assumed as GraphQLOperationType.query even if it isn't a query.
     * It doesn't cause a problem for now because it matters only when an operation is saved,
     * and ApolloDeveloperKit won't save any kind of operation given from devtool's GraphiQL.     *
     *
     * - Parameter operation: Operation object defined in JSON schema
     */
    convenience init(operation: Operation) {
        self.init(operationType: .query,
                  operationDefinition: operation.query,
                  operationIdentifier: operation.operationIdentifier,
                  operationName: operation.operationName ?? "",
                  variables: operation.variables as? GraphQLMap)
    }

    convenience init<Operation>(_ operation: Operation) where Operation: GraphQLOperation {
        self.init(operationType: operation.operationType,
                  operationDefinition: operation.operationDefinition,
                  operationIdentifier: operation.operationIdentifier,
                  operationName: operation.operationName,
                  variables: operation.variables)
    }

    private init(operationType: GraphQLOperationType, operationDefinition: String, operationIdentifier: String?, operationName: String, variables: GraphQLMap?) {
        self.operationType = operationType
        self.operationDefinition = operationDefinition
        self.operationIdentifier = operationIdentifier
        self.operationName = operationName
        self.variables = variables
    }
}
