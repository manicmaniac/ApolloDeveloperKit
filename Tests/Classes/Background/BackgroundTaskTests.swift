//
//  BackgroundTaskTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 3/1/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

#if os(iOS)
import UIKit

class BackgroundTaskTests: XCTestCase {
    private var executor: MockBackgroundTaskExecutor!
    private var backgroundTask: BackgroundTask!

    override func setUp() {
        executor = MockBackgroundTaskExecutor()
        backgroundTask = BackgroundTask(executor: executor)
    }

    func testBeginBackgroundTaskIfPossible_whenTaskIsNotRunning() {
        backgroundTask.beginBackgroundTaskIfPossible()
        XCTAssertEqual(Set(executor.expirationHandlersByActiveTaskIdentifier.keys), [backgroundTask.currentIdentifier])
    }

    func testBeginBackgroundTaskIfPossible_whenTaskIsAlreadyRunning() {
        backgroundTask.beginBackgroundTaskIfPossible()
        backgroundTask.beginBackgroundTaskIfPossible()
        XCTAssertEqual(Set(executor.expirationHandlersByActiveTaskIdentifier.keys), [backgroundTask.currentIdentifier])
    }

    func testBeginBackgroundTaskIfPossible_thenTaskExpires() {
        backgroundTask.beginBackgroundTaskIfPossible()
        executor.expireBackgroundTask(backgroundTask.currentIdentifier)
        XCTAssertTrue(executor.expirationHandlersByActiveTaskIdentifier.isEmpty)
        XCTAssertEqual(backgroundTask.currentIdentifier, .invalid)
    }
}

private class MockBackgroundTaskExecutor: BackgroundTaskExecutor {
    var expirationHandlersByActiveTaskIdentifier = [UIBackgroundTaskIdentifier: () -> Void]()

    func beginBackgroundTask(withName name: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier {
        XCTAssertEqual(name, "com.github.manicmaniac.ApolloDeveloperKit.BackgroundTask")
        let taskIdentifier = generateNewTaskIdentifier()
        expirationHandlersByActiveTaskIdentifier[taskIdentifier] = handler ?? {}
        return taskIdentifier
    }

    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        expirationHandlersByActiveTaskIdentifier[identifier] = nil
    }

    func expireBackgroundTask(_ identifier: UIBackgroundTaskIdentifier) {
        expirationHandlersByActiveTaskIdentifier[identifier]?()
    }

    private func generateNewTaskIdentifier() -> UIBackgroundTaskIdentifier {
        return UIBackgroundTaskIdentifier(rawValue: expirationHandlersByActiveTaskIdentifier.count + 1)
    }
}
#endif
