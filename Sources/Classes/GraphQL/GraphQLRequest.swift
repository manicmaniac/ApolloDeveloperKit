//
//  GraphQLRequest.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/23/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

public class GraphQLRequest: GraphQLOperation, JSONDecodable {
    public typealias Data = AnyGraphQLSelectionSet

    public let operationType: GraphQLOperationType
    public let operationDefinition: String
    public let variables: GraphQLMap?

    public init(operationType: GraphQLOperationType, operationDefinition: String, variables: GraphQLMap?) {
        self.operationType = operationType
        self.operationDefinition = operationDefinition
        self.variables = variables
    }

    public required init(jsonValue value: JSONValue) throws {
        guard let value = value as? [String: Any] else { fatalError() }
        self.variables = value["variables"].flatMap(GraphQLRequest.convertToGraphQLMap(_:))
        if let query = value["query"] as? String {
            self.operationType = .query
            self.operationDefinition = query
        } else if let mutation = value["mutation"] as? String {
            self.operationType = .mutation
            self.operationDefinition = mutation
        } else {
            throw JSONDecodingError.couldNotConvert(value: value, to: GraphQLRequest.self)
        }
    }

    private static func convertToGraphQLMap(_ object: Any) -> GraphQLMap {
        var map = GraphQLMap()
        for (key, value) in object as? [String: Any] ?? [:] {
            switch value {
            case let value as String:
                map[key] = value
            case let value as Array<Any>:
                map[key] = value
            case let value as Dictionary<AnyHashable, Any>:
                map[key] = value
            case is NSNull:
                map[key] = nil
            case let value as NSNumber:
                // https://stackoverflow.com/a/49641305
                switch CFGetTypeID(value as CFTypeRef) {
                case CFBooleanGetTypeID():
                    map[key] = value.boolValue
                case CFNumberGetTypeID():
                    switch CFNumberGetType(value as CFNumber) {
                    case .floatType, .doubleType:
                        map[key] = value.doubleValue
                    default:
                        map[key] = value.intValue
                    }
                default:
                    fatalError("The underlying type of value must be CFBoolean or CFNumber")
                }
            default:
                continue
            }
        }
        return map
    }
}
