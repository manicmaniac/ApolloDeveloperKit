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
        standardOutputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            self?.standardOutputPipeWillRead(fileHandle)
        }
        dup2(standardErrorPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        standardErrorPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            self?.standardErrorPipeWillRead(fileHandle)
        }
    }

    deinit {
        dup2(standardOutputFileDescriptor, STDOUT_FILENO)
        dup2(standardErrorFileDescriptor, STDERR_FILENO)
    }

    private func standardOutputPipeWillRead(_ fileHandle: FileHandle) {
        let data = fileHandle.availableData as NSData
        let written = write(standardOutputFileDescriptor, data.bytes, data.length)
        assert(written >= 0)
        queue.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.console(self, didWrite: data as Data, to: .standardOutput)
        }
    }

    private func standardErrorPipeWillRead(_ fileHandle: FileHandle) {
        let data = fileHandle.availableData as NSData
        let written = write(standardErrorFileDescriptor, data.bytes, data.length)
        assert(written >= 0)
        queue.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.console(self, didWrite: data as Data, to: .standardError)
        }
    }
}
