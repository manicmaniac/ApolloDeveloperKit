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

    init(event: EventStreamMessageConvertible) {
        self.init(rawData: event.message.rawData)
    }

    var data: Data {
        var data = Data(String(format: "%x\r\n", rawData.count).utf8)
        data.append(rawData)
        data.append(Data("\r\n".utf8))
        return data
    }
}
