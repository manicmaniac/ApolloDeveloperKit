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
    private let input = Pipe()
    private let output = Pipe()

    init() {
        input.fileHandleForReading.readabilityHandler = readabilityHandler
    }

    func open() {
        dup2(STDERR_FILENO, output.fileHandleForWriting.fileDescriptor)
        dup2(input.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
    }

    func close() {
        freopen("/dev/fd/2", "a", stderr)
        input.fileHandleForReading.closeFile()
        output.fileHandleForWriting.closeFile()
    }

    private func readabilityHandler(_ fileHandle: FileHandle) {
        let data = fileHandle.availableData
        delegate?.consoleLogger(self, log: data)
        try? output.fileHandleForWriting.writeData(data)
    }
}
