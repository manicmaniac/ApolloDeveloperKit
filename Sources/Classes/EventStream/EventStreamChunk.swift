//
//  EventStreamChunk.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/20/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

/**
 * `EventStreamChunk` represents an individual chunk of Chunked Transfer Coding.
 *
 * `EventStreamChunk` doesn't abstract anything of Server-Sent Events but only Chunked Transfer Coding,
 * where Server-Sent Events stands.
 *
 * - SeeAlso: [IETF RFC 7230](https://tools.ietf.org/html/rfc7230#section-4.1)
 */
public struct EventStreamChunk {
    private let rawData: Data

    init(rawData: Data = Data()) {
        self.rawData = rawData
    }

    var data: Data {
        var data = String(format: "%x\r\n", rawData.count).data(using: .utf8)!
        data.append(rawData)
        data.append("\r\n".data(using: .utf8)!)
        return data
    }
}
