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

    static let shared = ConsoleRedirection(standardOutputFileDescriptor: STDOUT_FILENO,
                                           standardErrorFileDescriptor: STDERR_FILENO,
                                           notificationCenter: .default,
                                           queue: .main,
                                           duplicator: defaultFileDescriptorDuplicator)
    private static let defaultFileDescriptorDuplicator = DarwinFileDescriptorDuplicator()

    private let notificationCenter: NotificationCenter
    private let queue: DispatchQueue
    private let duplicator: FileDescriptorDuplicator
    private let standardOutputPipe = Pipe()
    private let standardErrorPipe = Pipe()
    private let observerLock = NSLock()
    private let standardOutputFileDescriptor: Int32
    private let standardErrorFileDescriptor: Int32
    private var duplicatedStandardOutputFileDescriptor: Int32?
    private var duplicatedStandardErrorFileDescriptor: Int32?
    private var observersCount = 0

    /**
     * Initialize a new instance of `ConsoleRedirection`.
     *
     * DO NOT use this constructor. It is only visible for testing purpose.
     */
    init(standardOutputFileDescriptor: Int32,
         standardErrorFileDescriptor: Int32,
         notificationCenter: NotificationCenter,
         queue: DispatchQueue,
         duplicator: FileDescriptorDuplicator) {
        self.standardOutputFileDescriptor = standardOutputFileDescriptor
        self.standardErrorFileDescriptor = standardErrorFileDescriptor
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
        self.duplicatedStandardOutputFileDescriptor = duplicator.dup(standardOutputFileDescriptor)
        self.duplicatedStandardErrorFileDescriptor = duplicator.dup(standardErrorFileDescriptor)
        duplicator.dup2(standardOutputPipe.fileHandleForWriting.fileDescriptor, standardOutputFileDescriptor)
        standardOutputPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            try? self?.postNotificationAfterCopying(from: fileHandle, to: .standardOutput)
        }
        duplicator.dup2(standardErrorPipe.fileHandleForWriting.fileDescriptor, standardErrorFileDescriptor)
        standardErrorPipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            try? self?.postNotificationAfterCopying(from: fileHandle, to: .standardError)
        }
    }

    private func stop() {
        if let fileDescriptor = duplicatedStandardOutputFileDescriptor {
            duplicator.dup2(fileDescriptor, standardOutputFileDescriptor)
        }
        if let fileDescriptor = duplicatedStandardErrorFileDescriptor {
            duplicator.dup2(fileDescriptor, standardErrorFileDescriptor)
        }
    }

    private func postNotificationAfterCopying(from fileHandle: FileHandle, to destination: Destination) throws {
        guard let fileDescriptor = self.fileDescriptor(for: destination) else { return }
        let data = fileHandle.availableData
        errno = 0
        let written = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Int in
            guard let baseAddress = bytes.baseAddress else {
                // I think data.withUnsafeBytes doesn't pass a null pointer but just in case, ignore it.
                return 0
            }
            return write(fileDescriptor, baseAddress, data.count)
        }
        assert(written >= -1)
        if written == -1 {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
        queue.async { [weak self] in
            guard let self = self else { return }
            let notification = ConsoleDidWriteNotification(object: self, data: data, destination: destination)
            self.notificationCenter.post(notification.rawValue)
        }
    }

    private func fileDescriptor(for destination: Destination) -> Int32? {
        switch destination {
        case .standardOutput:
            return duplicatedStandardOutputFileDescriptor
        case .standardError:
            return duplicatedStandardErrorFileDescriptor
        }
    }
}
