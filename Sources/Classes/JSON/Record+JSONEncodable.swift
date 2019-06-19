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
        var jsonObject = JSONObject(minimumCapacity: fields.count)
        for (key, value) in fields {
            if let value = value as? JSONEncodable {
                jsonObject[key] = value.jsonValue
            } else {
                // As we cannot cast some kind of Objective-C types such as `NSCFString` to JSONEncodable,
                // assume it as naturally JSON-encodable object.
                jsonObject[key] = value
            }
        }
        return jsonObject
    }
}

extension Reference: JSONEncodable {
    public var jsonValue: JSONValue {
        return [
            "generated": true,
            "id": key,
            "type": "id",
            "typename": "TODO"
        ]
    }
}
