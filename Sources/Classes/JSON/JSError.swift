//
//  JSError.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/17/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

struct JSError: JSONEncodable {
    let message: String?
    let fileName: String? = nil
    let lineNumber: Int? = nil

    init(error: Error) {
        self.message = error.localizedDescription
    }

    // MARK: - JSONEncodable

    var jsonValue: JSONValue {
        return [
            "message": message.jsonValue,
            "fileName": fileName.jsonValue,
            "lineNumber": lineNumber.jsonValue
        ]
    }
}
