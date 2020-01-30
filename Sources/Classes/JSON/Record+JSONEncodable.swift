//
//  Record+JSONEncodable.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/15/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

extension Record: JSONEncodable {
    public var jsonValue: JSONValue {
        return fields.mapValues { value -> JSONValue in
            if let value = value as? JSONEncodable {
                return value.jsonValue
            }
            // As we cannot cast some kind of Objective-C types such as `NSCFString` to JSONEncodable,
            // assume it as naturally JSON-encodable object.
            return value
        }
    }
}
