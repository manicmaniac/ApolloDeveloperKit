//
//  EventStreamQueue.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/26/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

/**
 * `EventStreamQueue` is a thread-safe FIFO queue for `EventStreamChunk`.
 *
 * The both ends of the queue are assumed to be on different threads.
 * Otherwise it causes a deadlock.
 */
public class EventStreamQueue {
    private enum Condition {
        static let empty = 0
        static let nonempty = 1
    }

    private var queue = [EventStreamChunk]()
    private let condition = NSConditionLock(condition: Condition.empty)

    /**
     * Enqueue chunk to the queue.
     *
     * This method is thread-safe.
     */
    func enqueue(chunk: EventStreamChunk) {
        condition.lock()
        queue.append(chunk)
        condition.unlock(withCondition: Condition.nonempty)
    }

    /**
     * Dequeue chunk from the queue.
     *
     * This method is thread-safe.
     * When the queue is empty, this method blocks the thread until the new chunk is enqueued.
     */
    func dequeue() -> EventStreamChunk {
        condition.lock(whenCondition: Condition.nonempty)
        let chunk = queue.removeFirst()
        if queue.isEmpty {
            condition.unlock(withCondition: Condition.empty)
        } else {
            condition.unlock()
        }
        return chunk
    }
}
