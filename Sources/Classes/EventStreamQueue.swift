//
//  EventStreamQueue.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/20/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

struct EventStreamQueue<Key: Hashable> {
    private var queue = [Key: [EventStreamChunk]]()
    private var lock = NSLock()

    mutating func enqueue(chunk: EventStreamChunk, forKey key: Key) {
        lock.lock()
        defer { lock.unlock() }
        queue[key, default: []].append(chunk)
    }

    mutating func enqueueForAllKeys(chunk: EventStreamChunk) {
        for key in queue.keys {
            enqueue(chunk: chunk, forKey: key)
        }
    }

    mutating func dequeue(key: Key) -> EventStreamChunk? {
        lock.lock()
        defer { lock.unlock() }
        if queue[key]?.isEmpty == true {
            return nil
        }
        return queue[key]?.remove(at: 0)
    }
}
