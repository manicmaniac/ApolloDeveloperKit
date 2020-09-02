//
//  Schema+EventStreamMessageConvertible.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/29/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

extension ConsoleEvent: EventStreamMessageConvertible {
    var message: EventStreamMessage {
        return EventStreamMessage(event: String(describing: type), data: data)
    }
}

extension StateChange: EventStreamMessageConvertible {
    var message: EventStreamMessage {
        let data = try! JSONSerialization.data(withJSONObject: jsonValue)
        return EventStreamMessage(data: String(data: data, encoding: .utf8))
    }
}
