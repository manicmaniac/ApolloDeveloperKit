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

public class HTTPConnection {
    let fileHandle: FileHandle
    weak var delegate: HTTPConnectionDelegate?

    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }

    func write(_ data: Data) {
        do {
            try fileHandle.writeData(data)
        } catch {
            close()
        }
    }

    func close() {
        delegate?.httpConnectionWillClose(self)
        fileHandle.closeFile()
    }
}

// MARK: Hashable

extension HTTPConnection: Hashable {
    public static func == (lhs: HTTPConnection, rhs: HTTPConnection) -> Bool {
        return lhs.fileHandle == rhs.fileHandle
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(fileHandle)
    }
}
