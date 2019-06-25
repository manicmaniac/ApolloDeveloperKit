//
//  EventStreamQueue.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/26/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

class EventStreamQueue {
    private let lock = NSLock()
    private var queue = [EventStreamChunk]()

    func enqueue(chunk: EventStreamChunk) {
        lock.lock()
        defer { lock.unlock() }
        queue.append(chunk)
    }

    func dequeue() -> EventStreamChunk? {
        lock.lock()
        defer { lock.unlock() }
        return queue.isEmpty ? nil : queue.removeFirst()
    }
}
