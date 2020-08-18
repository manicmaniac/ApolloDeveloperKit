//
//  ConsoleRedirection.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/10/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

/**
 * `ConsoleRedirection` is a class responsible for manipulating file descriptors and notify its delegate when the files are written.
 */
final class ConsoleRedirection {
    enum Destination: Int {
        case standardOutput
        case standardError
    }

    private(set) static var shared = ConsoleRedirection(notificationCenter: .default, queue: .main, duplicator: defaultFileDescriptorDuplicator)
    private static let sharedInstanceLock = NSLock()
    private static let defaultFileDescriptorDuplicator = DarwinFileDescriptorDuplicator()

    private let notificationCenter: NotificationCenter
    private let queue: DispatchQueue
    private let duplicator: FileDescriptorDuplicator
    private let standardOutputPipe = Pipe()
    private let standardErrorPipe = Pipe()
    private let observerLock = NSLock()
    private var standardOutputFileDescriptor: Int32?
    private var standardErrorFileDescriptor: Int32?
    private var observersCount = 0

    /**
     * Set a given instance to be shared singleton instance.
     *
     * DO NOT use this method. It is only visible for testing purpose.
     */
    static func setShared(_ consoleRedirection: ConsoleRedirection) {
        sharedInstanceLock.lock()
        defer { sharedInstanceLock.unlock() }
        shared = consoleRedirection
    }

    /**
     * Initialize a new instance of `ConsoleRedirection`.
     *
     * DO NOT use this constructor. It is only visible for testing purpose.
     */
    init(notificationCenter: NotificationCenter, queue: DispatchQueue, duplicator: FileDescriptorDuplicator) {
        self.notificationCenter = notificationCenter
        self.queue = queue
        self.duplicator = duplicator
    }

    deinit {
        stop()
    }

    func addObserver(_ observer: Any, selector: Selector) {
        observerLock.lock()
        defer { observerLock.unlock() }
        notificationCenter.addObserver(observer, selector: selector, name: .consoleDidWrite, object: self)
        observersCount += 1
        if observersCount == 1 {
            start()
        }
    }

    func removeObserver(_ observer: Any) {
        observerLock.lock()
        defer { observerLock.unlock() }
        notificationCenter.removeObserver(observer)
        observersCount -= 1
        if observersCount == 0 {
            stop()
        }
    }

    private func start() {
        self.standardOutputFileDescriptor = duplicator.dup(STDOUT_FILENO)
        self.standardErrorFileDescriptor = duplicator.dup(STDERR_FILENO)
        duplicator.dup2(standardOutputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        standardOutputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            try? self?.standardOutputPipeWillRead(fileHandle)
        }
        duplicator.dup2(standardErrorPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        standardErrorPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            try? self?.standardErrorPipeWillRead(fileHandle)
        }
    }

    private func stop() {
        if let fileDescriptor = standardOutputFileDescriptor {
            duplicator.dup2(fileDescriptor, STDOUT_FILENO)
        }
        if let fileDescriptor = standardErrorFileDescriptor {
            duplicator.dup2(fileDescriptor, STDERR_FILENO)
        }
    }

    private func standardOutputPipeWillRead(_ fileHandle: FileHandle) throws {
        guard let standardOutputFileDescriptor = standardOutputFileDescriptor else { return }
        let data = fileHandle.availableData
        let written = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Int in
            guard let baseAddress = bytes.baseAddress else { return 0 }
            return write(standardOutputFileDescriptor, baseAddress, bytes.count)
        }
        assert(written >= -1)
        if written == -1 {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
        queue.async { [weak self] in
            guard let self = self else { return }
            let notification = ConsoleDidWriteNotification(object: self, data: data, destination: .standardOutput)
            self.notificationCenter.post(notification.rawValue)
        }
    }

    private func standardErrorPipeWillRead(_ fileHandle: FileHandle) throws {
        guard let standardErrorFileDescriptor = standardErrorFileDescriptor else { return }
        let data = fileHandle.availableData
        let written = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Int in
            guard let baseAddress = bytes.baseAddress else { return 0 }
            return write(standardErrorFileDescriptor, baseAddress, data.count)
        }
        assert(written >= -1)
        if written == -1 {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
        queue.async { [weak self] in
            guard let self = self else { return }
            let notification = ConsoleDidWriteNotification(object: self, data: data, destination: .standardError)
            self.notificationCenter.post(notification.rawValue)
        }
    }
}
