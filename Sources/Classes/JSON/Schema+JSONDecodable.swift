//
//  Schema+JSONDecodable.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/22/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo

extension Operation: JSONDecodable {
    init(jsonValue value: JSONValue) throws {
        guard let jsonObject = value as? JSONObject, let query = jsonObject["query"] as? String else {
            throw JSONDecodingError.couldNotConvert(value: value, to: Operation.self)
        }
        self.operationIdentifier = jsonObject["operationIdentifier"] as? String
        self.operationName = jsonObject["operationName"] as? String
        self.query = query
        self.variables = jsonObject["variables"] as? [String: Any]
    }
}
