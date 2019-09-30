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
    func testDequeue_whenEmpty() {
        let operationQueue = OperationQueue()
        operationQueue.name = "com.github.manicmaniac.ApolloDeveloperKitTests.\(name)"
        let operation = BlockOperation {
            let queue = EventStreamQueue()
            _ = queue.dequeue()
            XCTFail("dequeue should never finishes")
        }
        operationQueue.addOperation(operation)
        Thread.sleep(forTimeInterval: 0.25)
        operation.cancel()
    }

    func testEnqueueAndDequeue_whenInMainThread() {
        let queue = EventStreamQueue()
        let chunk = EventStreamChunk()
        queue.enqueue(chunk: chunk)
        let dequeuedChunk = queue.dequeue()
        XCTAssertEqual(dequeuedChunk.data, chunk.data)
    }

    func testEnqueueAndDequeue_whenInDifferentThreads() {
        let queue = EventStreamQueue()
        let chunk = EventStreamChunk()
        let expectationForEnqueue = expectation(description: "enqueue should finish")
        let enqueueOperationQueue = OperationQueue()
        enqueueOperationQueue.name = "com.github.manicmaniac.ApolloDeveloperKitTests.\(name).enqueue"
        let enqueueOperation = BlockOperation {
            queue.enqueue(chunk: chunk)
            expectationForEnqueue.fulfill()
        }
        let expectationForDequeue = expectation(description: "dequeue should finish")
        let dequeueOperationQueue = OperationQueue()
        dequeueOperationQueue.name = "com.github.manicmaniac.ApolloDeveloperKitTests.\(name).dequeue"
        let dequeueOperation = BlockOperation {
            let dequeuedChunk = queue.dequeue()
            XCTAssertEqual(dequeuedChunk.data, chunk.data)
            expectationForDequeue.fulfill()
        }
        enqueueOperationQueue.addOperation(enqueueOperation)
        dequeueOperationQueue.addOperation(dequeueOperation)
        waitForExpectations(timeout: 0.25, handler: nil)
    }
}
