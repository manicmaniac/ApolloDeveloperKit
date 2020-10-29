//
//  GraphQLResult+JSONEncodable.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/28/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

extension GraphQLResult: GraphQLInputValue, JSONEncodable where Data: GraphQLSelectionSet {
    public var jsonValue: JSONValue {
        var dictionary = [String: Any]()
        if let data = data {
            dictionary["data"] = data.jsonObject
        }
        if let errors = errors {
            dictionary["errors"] = errors
        }
        return dictionary
    }
}
