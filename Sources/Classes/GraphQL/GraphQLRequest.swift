//
//  GraphQLRequest.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/23/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

/**
 * `GraphQLRequest` is the class representing any kind of GraphQL operation including query, mutation and subscription.
 *
 * Any kind of oepration is recognized as GraphQLOperationType.query even if it isn't a query.
 * It doesn't cause a problem for now because it matters only when an operation is saved,
 * and ApolloDeveloperKit won't save any kind of operation given from devtool's GraphiQL.
 */
public class GraphQLRequest: GraphQLOperation {
    public typealias Data = AnyGraphQLSelectionSet

    /**
     * The type of an actual operation.
     *
     * Always be a GraphQLOperationType.query even if it isn't a query.
     */
    public let operationType: GraphQLOperationType

    /**
     * The query document of an operation.
     */
    public let operationDefinition: String

    /**
     * The identifier of an operation.
     */
    public let operationIdentifier: String?

    /**
     * The name of an operation.
     */
    public let operationName: String

    /**
     * The query variables of an operation.
     */
    public let variables: GraphQLMap?

    /**
     * Initializes a GraphQLRequest object.
     *
     * - Parameter jsonObject: JSON dictionary object that conforms to GraphQL request.
     * - Throws: `JSONDecodableError` when JSON could not be converted to GraphQL request.
     */
    public convenience init(jsonObject: Any) throws {
        if let jsonObject = jsonObject as? [String: Any], let query = jsonObject["query"] as? String {
            let operationName = jsonObject["operationName"] as? String ?? ""
            let variables = jsonObject["variables"].flatMap(GraphQLRequest.convertToGraphQLMap(_:))
            self.init(operationType: .query, operationDefinition: query, operationIdentifier: nil, operationName: operationName, variables: variables)
        } else {
            throw JSONDecodingError.couldNotConvert(value: jsonObject, to: GraphQLRequest.self)
        }
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
            return convertNumberToJSONEncodable(value)
        default:
            fatalError("invalid type of value: \(type(of: jsonObject))")
        }
    }

    private static func convertNumberToJSONEncodable(_ number: NSNumber) -> JSONEncodable {
        switch CFGetTypeID(number) {
        case CFBooleanGetTypeID():
            return number.boolValue
        case CFNumberGetTypeID():
            switch CFNumberGetType(number) {
            case .floatType, .doubleType, .float32Type, .float64Type, .cgFloatType:
                return number.doubleValue
            default:
                return number.intValue
            }
        default:
            fatalError("The underlying type of value must be CFBoolean or CFNumber")
        }
    }
}
