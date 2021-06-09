//
//  Logger.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/9/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Foundation
import asl
import os.log

final class Logger {
    static let apollo = Logger(category: "apollo")
    static let http = Logger(category: "http")

    private let logger: Any
    private var isSuspending = false

    init?(category: String) {
        guard ProcessInfo().environment.keys.contains("APOLLO_DEVELOPER_KIT_DIAGNOSTICS") else {
            return nil
        }
        let subsystem = "com.github.manicmaniac.ApolloDeveloperKit"
        if #available(macOS 10.12, iOS 10, *) {
            logger = OSLog(subsystem: subsystem, category: category)
        } else {
            logger = asl_new(UInt32(ASL_TYPE_MSG))!
        }
    }

    func debug(_ message: @autoclosure () -> String) {
        log(level: .debug, message())
    }

    func info(_ message: @autoclosure () -> String) {
        log(level: .info, message())
    }

    func error(_ message: @autoclosure () -> String) {
        log(level: .error, message())
    }

    func withSuspending(_ body: () throws -> Void) rethrows {
        isSuspending = true
        defer { isSuspending = false }
        try body()
    }

    private func log(level: LogLevel, _ message: String) {
        if isSuspending { return }
        if #available(macOS 10.12, iOS 10, *) {
            os_log("%@", log: logger as! OSLog, type: level.osLogType, message)
        } else {
            asl_vlog((logger as! asl_object_t), nil, level.aslLogLevel, "%@", getVaList([message]))
        }
    }

}

private enum LogLevel {
    case debug
    case info
    case error

    @available(macOS 10.12, iOS 10, *)
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .error:
            return .error
        }
    }

    var aslLogLevel: Int32 {
        switch self {
        case .debug:
            return ASL_LEVEL_DEBUG
        case .info:
            return ASL_LEVEL_INFO
        case .error:
            return ASL_LEVEL_ERR
        }
    }
}

