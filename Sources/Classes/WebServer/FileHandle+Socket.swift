//
//  FileHandle+Socket.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/30/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

extension FileHandle {
    func write(_ data: Data, ignoringBrokenPipe: Bool) {
        guard ignoringBrokenPipe else {
            return write(data)
        }
        var totalWritten = 0
        while totalWritten < data.count {
            let written = data.withUnsafeBytes { bytes in
                Darwin.write(fileDescriptor, bytes.advanced(by: totalWritten), data.count - totalWritten)
            }
            if written <= 0 {
                return
            }
            totalWritten += written
        }
    }
}
