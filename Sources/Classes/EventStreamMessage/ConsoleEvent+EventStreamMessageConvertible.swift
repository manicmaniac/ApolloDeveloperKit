//
//  ConsoleEvent+EventStreamMessageConvertible.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/29/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

extension ConsoleEvent: EventStreamMessageConvertible {
    var message: EventStreamMessage {
        return EventStreamMessage(event: String(describing: type), data: data)
    }
}
