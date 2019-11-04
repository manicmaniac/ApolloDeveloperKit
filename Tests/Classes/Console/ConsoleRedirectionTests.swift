//
//  ConsoleRedirectionTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 11/5/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class ConsoleRedirectionTests: XCTestCase {
    private var delegateHandler: ConsoleRedirectionDelegateHandler!
    private var mockDuplicator: MockFileDescriptorDuplicator!

    override func setUp() {
        delegateHandler = ConsoleRedirectionDelegateHandler()
        mockDuplicator = MockFileDescriptorDuplicator()
    }

    func testInit() {
        // Assigning to placeholder `_` doesn't retain the right side value so assigning to a named variable is necessary.
        let consoleRedirection = ConsoleRedirection(delegate: delegateHandler, queue: .main, duplicator: mockDuplicator)
        _ = consoleRedirection.self // To suppress a warning for the unused variable.
        XCTAssertEqual(mockDuplicator.dupInvocationHistory, [1, 2])
        guard mockDuplicator.dup2InvocationHistory.count == 2 else {
            return XCTFail("dup2 must be called exactly twice but called \(mockDuplicator.dup2InvocationHistory.count) times.")
        }
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[0].fildes2, 1)
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[1].fildes2, 2)
    }

    func testDeinit() {
        var consoleRedirection: ConsoleRedirection? = ConsoleRedirection(delegate: delegateHandler, queue: .main, duplicator: mockDuplicator)
        _ = consoleRedirection.self // To suppress a warning for the unused variable.
        mockDuplicator.clearInvocationHistory()
        consoleRedirection = nil
        guard mockDuplicator.dup2InvocationHistory.count == 2 else {
            return XCTFail("dup2 must be called exactly twice but called \(mockDuplicator.dup2InvocationHistory.count) times.")
        }
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[0].fildes2, 1)
        XCTAssertEqual(mockDuplicator.dup2InvocationHistory[1].fildes2, 2)
    }
}

private class ConsoleRedirectionDelegateHandler: ConsoleRedirectionDelegate {
    var consoleDidWriteDataToDestinationCallback: ((ConsoleRedirection, Data, ConsoleRedirection.Destination) -> Void)?

    func console(_ console: ConsoleRedirection, didWrite data: Data, to destination: ConsoleRedirection.Destination) {
        consoleDidWriteDataToDestinationCallback?(console, data, destination)
    }
}

private class MockFileDescriptorDuplicator: FileDescriptorDuplicator {
    private(set) var dupInvocationHistory = [Int32]()
    private(set) var dup2InvocationHistory = [(fildes: Int32, fildes2: Int32)]()

    func dup(_ fildes: Int32) -> Int32 {
        dupInvocationHistory.append(fildes)
        return fildes
    }

    func dup2(_ fildes: Int32, _ fildes2: Int32) -> Int32 {
        dup2InvocationHistory.append((fildes, fildes2))
        return fildes2
    }

    func clearInvocationHistory() {
        dupInvocationHistory.removeAll()
        dup2InvocationHistory.removeAll()
    }
}
