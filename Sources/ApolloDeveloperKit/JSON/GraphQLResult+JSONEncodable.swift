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
        if let data = data {
            return data.jsonObject
        }
        if let errors = errors {
            return errors
        }
        return NSNull()
    }
}
