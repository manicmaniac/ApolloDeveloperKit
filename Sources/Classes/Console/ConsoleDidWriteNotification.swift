//
//  ConsoleDidWriteNotification.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/18/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

extension Notification.Name {
    // `userInfo` will be ["data": Data, "destination": ConsoleRedirection.Destination]
    static let consoleDidWrite = Notification.Name("ADKConsoleDidWriteNotification")
}

struct ConsoleDidWriteNotification: RawRepresentable {
    private static let dataKey = "data"
    private static let destinationKey = "destination"

    let rawValue: Notification

    init(object: ConsoleRedirection, data: Data, destination: ConsoleRedirection.Destination) {
        self.rawValue = Notification(name: .consoleDidWrite, object: object, userInfo: [
            ConsoleDidWriteNotification.dataKey: data,
            ConsoleDidWriteNotification.destinationKey: destination
        ])
    }

    init?(rawValue: Notification) {
        guard rawValue.name == Notification.Name.consoleDidWrite else { return nil }
        self.rawValue = rawValue
    }

    var object: ConsoleRedirection {
        return rawValue.object as! ConsoleRedirection
    }

    var data: Data {
        return rawValue.userInfo![ConsoleDidWriteNotification.dataKey] as! Data
    }

    var destination: ConsoleRedirection.Destination {
        return rawValue.userInfo![ConsoleDidWriteNotification.destinationKey] as! ConsoleRedirection.Destination
    }
}
