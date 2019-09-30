//
//  Reference+JSONEncodable.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

extension Reference: JSONEncodable {
    public var jsonValue: JSONValue {
        return [
            "generated": true,
            "id": key,
            "type": "id"
        ]
    }
}
