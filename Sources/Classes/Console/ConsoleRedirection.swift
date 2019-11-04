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

    private static let defaultDuplicator = DarwinFileDescriptorDuplicator()

    private weak var delegate: ConsoleRedirectionDelegate?
    private let queue: DispatchQueue
    private let duplicator: FileDescriptorDuplicator
    private let standardOutputFileDescriptor: Int32
    private let standardErrorFileDescriptor: Int32
    private let standardOutputPipe = Pipe()
    private let standardErrorPipe = Pipe()

    init(delegate: ConsoleRedirectionDelegate, queue: DispatchQueue = .main, duplicator: FileDescriptorDuplicator = ConsoleRedirection.defaultDuplicator) {
        self.delegate = delegate
        self.queue = queue
        self.duplicator = duplicator
        self.standardOutputFileDescriptor = duplicator.dup(STDOUT_FILENO)
        self.standardErrorFileDescriptor = duplicator.dup(STDERR_FILENO)
        duplicator.dup2(standardOutputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        standardOutputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            self?.standardOutputPipeWillRead(fileHandle)
        }
        duplicator.dup2(standardErrorPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        standardErrorPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            self?.standardErrorPipeWillRead(fileHandle)
        }
    }

    deinit {
        duplicator.dup2(standardOutputFileDescriptor, STDOUT_FILENO)
        duplicator.dup2(standardErrorFileDescriptor, STDERR_FILENO)
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
