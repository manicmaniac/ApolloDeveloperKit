//
//  GraphQLRequest.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/23/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

/**
 * `GraphQLRequest` is the class representing any kind of GraphQL operation including query, mutation and subscription.
 *
 * Any kind of operation is recognized as GraphQLOperationType.query even if it isn't a query.
 * It doesn't cause a problem for now because it matters only when an operation is saved,
 * and ApolloDeveloperKit won't save any kind of operation given from devtool's GraphiQL.
 */
class GraphQLRequest: GraphQLOperation, JSONDecodable {
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
     * Initializes a GraphQLRequest object.
     *
     * - Parameter jsonObject: JSON dictionary object that conforms to GraphQL request.
     * - Throws: `JSONDecodableError` when JSON could not be converted to GraphQL request.
     */
    required convenience init(jsonValue value: Any) throws {
        guard let jsonObject = value as? [String: Any], let query = jsonObject["query"] as? String else {
            throw JSONDecodingError.couldNotConvert(value: value, to: GraphQLRequest.self)
        }
        let operationIdentifier = jsonObject["operationIdentifier"] as? String
        let operationName = jsonObject["operationName"] as? String ?? ""
        let variables = jsonObject["variables"].flatMap(GraphQLRequest.convertToGraphQLMap(_:))
        self.init(operationType: .query,
                  operationDefinition: query,
                  operationIdentifier: operationIdentifier,
                  operationName: operationName,
                  variables: variables)
    }

    private init(operationType: GraphQLOperationType, operationDefinition: String, operationIdentifier: String?, operationName: String, variables: GraphQLMap?) {
        self.operationType = operationType
        self.operationDefinition = operationDefinition
        self.operationIdentifier = operationIdentifier
        self.operationName = operationName
        self.variables = variables
    }

    private static func convertToGraphQLMap(_ object: Any) -> GraphQLMap {
        return recursivelyConvertToJSONEncodable(object) as! GraphQLMap
    }

    private static func recursivelyConvertToJSONEncodable(_ jsonObject: Any) -> JSONEncodable {
        switch jsonObject {
        case let value as String:
            return value
        case let value as [Any]:
            return value.map(recursivelyConvertToJSONEncodable(_:))
        case let value as [String: Any]:
            return value.mapValues(recursivelyConvertToJSONEncodable(_:))
        case is NSNull:
            return JSONEncodable?.none
        case let value as NSNumber:
            return value
        default:
            fatalError("invalid type of value: \(type(of: jsonObject))")
        }
    }
}
