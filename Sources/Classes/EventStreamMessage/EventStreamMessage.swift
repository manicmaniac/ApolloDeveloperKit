//
//  EventStreamMessage.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/29/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

protocol EventStreamMessageConvertible {
    var message: EventStreamMessage { get }
}

struct EventStreamMessage: RawRepresentable {
    static let ping = EventStreamMessage(rawValue: ":\n\n")!

    let rawValue: String

    init?(rawValue: String) {
        guard rawValue.hasSuffix("\n\n") else { return nil }
        self.rawValue = rawValue
    }

    init(event: String? = nil, data: String? = nil, id: String? = nil, retry: Int? = nil) {
        var value = ""
        if let event = event {
            value.append("event: \(event)\n")
        }
        if let data = data {
            value.append(data.split(separator: "\n").map { "data: \($0)\n" }.joined())
        }
        if let id = id {
            value.append("id: \(id)\n")
        }
        if let retry = retry {
            value.append("retry: \(retry)\n")
        }
        value.append("\n")
        self.rawValue = value
    }

    var rawData: Data {
        return Data(rawValue.utf8)
    }
}

// MARK: Equatable

extension EventStreamMessage: Equatable {
    static func == (lhs: EventStreamMessage, rhs: EventStreamMessage) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

// MARK: Hashable

extension EventStreamMessage: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(rawValue)
    }
}

// MARK: CustomStringConvertible

extension EventStreamMessage: CustomStringConvertible {
    var description: String {
        return rawValue
    }
}

// MARK: LosslessStringConvertible

extension EventStreamMessage: LosslessStringConvertible {
    init?(_ description: String) {
        self.init(rawValue: description)
    }
}

// MARK: EventStreamMessageConvertible

extension EventStreamMessage: EventStreamMessageConvertible {
    var message: EventStreamMessage {
        return self
    }
}
