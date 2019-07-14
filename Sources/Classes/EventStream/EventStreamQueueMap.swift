//
//  EventStreamQueueMap.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/20/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

/**
 * `EventStreamQueueMap` is like a dictionary that the keys are individual request identifiers and values are `EventStreamQueue`s.
 *
 * Keys are not retained by this class so that they don't leak memory and automatically removes obsolete queues.
 * All methods of this class are thread-safe.
 */
public class EventStreamQueueMap<Key: AnyObject> {
    private let queuesByKey = NSMapTable<Key, EventStreamQueue>.weakToStrongObjects()

    /**
     * The number of elements.
     */
    var count: Int {
        return queuesByKey.keyEnumerator().allObjects.count
    }

    /**
     * A Boolean value indicating whether the collection is empty.
     */
    var isEmpty: Bool {
        return count == 0
    }

    /**
     * Enqueue a chunk for a perticular request.
     *
     * - Parameter chunk: A chunk to be enqueued.
     * - Parameter key: An object identifying the corresponding request.
     */
    func enqueue(chunk: EventStreamChunk, forKey key: Key) {
        if let queue = queuesByKey.object(forKey: key) {
            queue.enqueue(chunk: chunk)
        } else {
            let queue = EventStreamQueue()
            queue.enqueue(chunk: chunk)
            queuesByKey.setObject(queue, forKey: key)
        }
    }

    /**
     * Enqueue a chunk for all requests like a broadcast.
     *
     * - Parameter chunk: A chunk to be enqueued.
     */
    func enqueueForAllKeys(chunk: EventStreamChunk) {
        for key in queuesByKey.keyEnumerator() {
            enqueue(chunk: chunk, forKey: key as! Key)
        }
    }

    /**
     * Dequeue a chunk for a perticular request.
     *
     * This method blocks the thread only when the designated queue exists and it's empty.
     *
     * - Parameter key: An object identifying the request.
     * - Returns: A chunk corresponding to the request in the queue.
     */
    func dequeue(key: Key) -> EventStreamChunk? {
        return queuesByKey.object(forKey: key)?.dequeue()
    }
}
