//
//  GraphQLRequest.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/23/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

public class GraphQLRequest: GraphQLOperation {
    public typealias Data = AnyGraphQLSelectionSet

    public let operationType: GraphQLOperationType
    public let operationDefinition: String
    public let variables: GraphQLMap?

    public init(operationType: GraphQLOperationType, operationDefinition: String, variables: GraphQLMap?) {
        self.operationType = operationType
        self.operationDefinition = operationDefinition
        self.variables = variables
    }

    public init(jsonObject: Any) throws {
        guard let jsonObject = jsonObject as? [String: Any] else { fatalError() }
        self.variables = jsonObject["variables"].flatMap(GraphQLRequest.convertToGraphQLMap(_:))
        if let query = jsonObject["query"] as? String {
            // Any kind of operations are recognized as GraphQLOperationType.query type even if they are mutations.
            // It doesn't cause a problem for now because it matters only when operations are saved,
            // and ApolloDeveloperKit won't save any operations given from GraphiQL.
            self.operationType = .query
            self.operationDefinition = query
        } else {
            throw JSONDecodingError.couldNotConvert(value: jsonObject, to: GraphQLRequest.self)
        }
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
