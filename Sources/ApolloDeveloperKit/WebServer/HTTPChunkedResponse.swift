//
//  HTTPChunkedResponse.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 11/3/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

/**
 * `HTTPChunkedResponse` represents an individual chunk of Chunked Transfer Encoding.
 *
 * - SeeAlso: [IETF RFC 7230](https://tools.ietf.org/html/rfc7230#section-4.1)
 */
struct HTTPChunkedResponse {
    private let rawData: Data

    init(rawData: Data) {
        self.rawData = rawData
    }

    init(string: String) {
        self.rawData = string.data(using: .utf8)!
    }

    var data: Data {
        var data = String(format: "%x\r\n", rawData.count).data(using: .utf8)!
        data.append(rawData)
        data.append("\r\n".data(using: .utf8)!)
        return data
    }
}
