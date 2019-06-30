//
//  EventStreamQueueTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class EventStreamQueueTests: XCTestCase {
    func testDequeue() {
        XCTContext.runActivity(named: "when empty") { _ in
            let subthread = Thread {
                let queue = EventStreamQueue()
                _ = queue.dequeue()
                XCTFail("dequeue should never finishes")
            }
            subthread.start()
            Thread.sleep(forTimeInterval: 0.25)
            subthread.cancel()
        }
    }

    func testEnqueueAndDequeue() {
        XCTContext.runActivity(named: "in the main thread") { _ in
            let queue = EventStreamQueue()
            let chunk = EventStreamChunk(data: Data(), error: nil)
            queue.enqueue(chunk: chunk)
            let dequeuedChunk = queue.dequeue()
            XCTAssertEqual(dequeuedChunk.data, chunk.data)
            XCTAssertNil(dequeuedChunk.error)
        }
        XCTContext.runActivity(named: "in the different threads") { _ in
            let queue = EventStreamQueue()
            let chunk = EventStreamChunk(data: Data(), error: nil)
            let expectationForEnqueue = expectation(description: "enqueue is finished")
            let enqueueThread = Thread {
                queue.enqueue(chunk: chunk)
                expectationForEnqueue.fulfill()
            }
            let expectationForDequeue = expectation(description: "dequeue is finished")
            let dequeueThread = Thread {
                let dequeuedChunk = queue.dequeue()
                XCTAssertEqual(dequeuedChunk.data, chunk.data)
                XCTAssertNil(dequeuedChunk.error)
                expectationForDequeue.fulfill()
            }
            dequeueThread.start()
            enqueueThread.start()
            waitForExpectations(timeout: 0.25, handler: nil)
        }
    }
}
