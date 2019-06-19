//
//  EventStreamQueue.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/20/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

struct EventStreamQueue<Key: AnyObject> {
    private var queuesByKey = NSMapTable<Key, NSMutableArray>.weakToStrongObjects()
    private var lock = NSLock()

    mutating func enqueue(chunk: EventStreamChunk, forKey key: Key) {
        lock.lock()
        defer { lock.unlock() }
        let queue = queuesByKey.object(forKey: key)
        if let queue = queue {
            queue.add(chunk)
        } else {
            queuesByKey.setObject(NSMutableArray(object: chunk), forKey: key)
        }
    }

    mutating func enqueueForAllKeys(chunk: EventStreamChunk) {
        for key in queuesByKey.keyEnumerator() {
            enqueue(chunk: chunk, forKey: key as! Key)
        }
    }

    mutating func dequeue(key: Key) -> EventStreamChunk? {
        lock.lock()
        defer { lock.unlock() }
        if let queue = queuesByKey.object(forKey: key), let chunk = queue.firstObject as? EventStreamChunk {
            queue.removeObject(at: 0)
            return chunk
        }
        return nil
    }
}
