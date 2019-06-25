//
//  EventStreamQueue.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/26/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

class EventStreamQueue {
    private enum Condition {
        static let empty = 0
        static let nonempty = 1
    }

    private var queue = [EventStreamChunk]()
    private let condition = NSConditionLock(condition: Condition.empty)

    func enqueue(chunk: EventStreamChunk) {
        condition.lock()
        queue.append(chunk)
        condition.unlock(withCondition: Condition.nonempty)
    }

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
