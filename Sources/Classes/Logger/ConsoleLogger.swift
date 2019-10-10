//
//  ConsoleLogger.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/6/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

protocol ConsoleLoggerDelegate: class {
    func consoleLogger(_ consoleLogger: ConsoleLogger, log data: Data)
}

class ConsoleLogger {
    weak var delegate: ConsoleLoggerDelegate?
    private var redirection: ConsoleRedirection?

    func open() {
        redirection = ConsoleRedirection(delegate: self)
    }

    func close() {
        redirection = nil
    }
}

// MARK: ConsoleRedirectionDelegate

extension ConsoleLogger: ConsoleRedirectionDelegate {
    func console(_ console: ConsoleRedirection, standardOutputDidWrite data: Data) {
        delegate?.consoleLogger(self, log: data)
    }

    func console(_ console: ConsoleRedirection, standardErrorDidWrite data: Data) {
        delegate?.consoleLogger(self, log: data)
    }
}
