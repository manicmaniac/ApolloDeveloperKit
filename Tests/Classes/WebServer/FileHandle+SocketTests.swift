//
//  FileHandle+SocketTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 2/2/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class FileHandle_SocketTests: XCTestCase {
    private var fileHandle: FileHandle!

    override func setUp() {
        let templateURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(NSStringFromClass(type(of: self))).XXXXXX")
        let templatePointer = templateURL.withUnsafeFileSystemRepresentation(UnsafeMutablePointer.init(mutating:))!
        let fileDescriptor = mkstemp(templatePointer)
        do {
            guard fileDescriptor != -1 && unlink(templatePointer) != -1 else {
                throw POSIXError(POSIXErrorCode(rawValue: errno)!)
            }
            fileHandle = FileHandle(fileDescriptor: fileDescriptor, closeOnDealloc: true)
        } catch let error {
            XCTFail(String(describing: error))
        }
    }

    func testWrite_withLongBytes() throws {
        var generator = SystemRandomNumberGenerator()
        let buffer = Array(AnyIterator { generator.next(upperBound: UInt8.max) }.prefix(1024 * 1024))
        let longData = Data(bytes: buffer, count: buffer.count) as NSData
        try fileHandle.write(bytes: longData.bytes, length: longData.length)
        fileHandle.seek(toFileOffset: 0)
        let writtenData = fileHandle.readDataToEndOfFile() as NSData
        XCTAssertEqual(longData, writtenData)
    }
}
