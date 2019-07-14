//
//  EventStreamChunk.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/20/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

/**
 * `EventStreamChunk` represents an individual chunk of Server-Sent Event.
 *
 * - SeeAlso: [IETF RFC 6202](https://tools.ietf.org/html/rfc6202#section-4.3)
 */
public struct EventStreamChunk {
    let data: Data
    let error: Error?
}
