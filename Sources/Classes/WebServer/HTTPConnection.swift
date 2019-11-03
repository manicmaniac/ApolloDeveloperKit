//
//  HTTPConnection.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 10/3/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

protocol HTTPConnectionDelegate: class {
    func httpConnectionWillClose(_ connection: HTTPConnection)
}

class HTTPConnection {
    let fileHandle: FileHandle
    weak var delegate: HTTPConnectionDelegate?
    private let lock = NSRecursiveLock()
    private var isFileHandleOpen = true

    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }

    func write(_ data: Data) {
        lock.lock()
        defer { lock.unlock() }
        guard isFileHandleOpen else { return }
        do {
            try fileHandle.writeData(data)
        } catch {
            close()
        }
    }

    func close() {
        lock.lock()
        defer { lock.unlock() }
        guard isFileHandleOpen else { return }
        delegate?.httpConnectionWillClose(self)
        fileHandle.closeFile()
        isFileHandleOpen = false
    }
}

// MARK: Hashable

extension HTTPConnection: Hashable {
    static func == (lhs: HTTPConnection, rhs: HTTPConnection) -> Bool {
        return lhs.fileHandle == rhs.fileHandle
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fileHandle)
    }
}
