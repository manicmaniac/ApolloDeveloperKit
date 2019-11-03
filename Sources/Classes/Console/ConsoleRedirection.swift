//
//  ConsoleRedirection.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/10/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

protocol ConsoleRedirectionDelegate: class {
    func console(_ console: ConsoleRedirection, didWrite data: Data, to destination: ConsoleRedirection.Destination)
}

class ConsoleRedirection {
    enum Destination {
        case standardOutput
        case standardError
    }

    private weak var delegate: ConsoleRedirectionDelegate?
    private let queue: DispatchQueue
    private let standardOutputFileDescriptor = dup(STDOUT_FILENO)
    private let standardErrorFileDescriptor = dup(STDERR_FILENO)
    private let standardOutputPipe = Pipe()
    private let standardErrorPipe = Pipe()

    init(delegate: ConsoleRedirectionDelegate, queue: DispatchQueue = .main) {
        self.delegate = delegate
        self.queue = queue
        dup2(standardOutputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        standardOutputPipe.fileHandleForReading.readabilityHandler = standardOutputPipeWillRead(_:)
        dup2(standardErrorPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        standardErrorPipe.fileHandleForReading.readabilityHandler = standardErrorPipeWillRead(_:)
    }

    deinit {
        dup2(standardOutputFileDescriptor, STDOUT_FILENO)
        dup2(standardErrorFileDescriptor, STDERR_FILENO)
    }

    private func standardOutputPipeWillRead(_ fileHandle: FileHandle) {
        let data = fileHandle.availableData as NSData
        assert(write(standardOutputFileDescriptor, data.bytes, data.length) >= 0)
        queue.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.console(self, didWrite: data as Data, to: .standardOutput)
        }
    }

    private func standardErrorPipeWillRead(_ fileHandle: FileHandle) {
        let data = fileHandle.availableData as NSData
        assert(write(standardErrorFileDescriptor, data.bytes, data.length) >= 0)
        queue.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.console(self, didWrite: data as Data, to: .standardError)
        }
    }
}
