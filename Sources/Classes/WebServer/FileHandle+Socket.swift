//
//  FileHandle+Socket.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/30/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

extension FileHandle {
    /**
     * Synchronously writes the specified data to the receiver ignoring `EPIPE` error.
     *
     * Since `FileHandle.write(_:)` throws an Objective-C level exception when the native socket is closed,
     * we have to write raw bytes with POSIX `write(2)`.
     * This is the workaround to avoid using `write(2)` as it is.
     */
    func writeData(_ data: Data) throws {
        var totalWritten = 0
        while totalWritten < data.count {
            let written = Darwin.write(fileDescriptor, (data as NSData).bytes.advanced(by: totalWritten), data.count - totalWritten)
            if written <= 0 {
                throw POSIXError(POSIXErrorCode(rawValue: errno)!)
            }
            totalWritten += written
        }
    }
}
