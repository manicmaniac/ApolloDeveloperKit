//
//  DebuggableNormalizedCache.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/15/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

protocol DebuggableNormalizedCacheDelegate: class {
    func normalizedCache(_ normalizedCache: DebuggableNormalizedCache, didChangeRecords records: RecordSet)
}

/**
 * `DebuggableNormalizedCache` is a bridge between `ApolloDebugServer` and `ApolloStore`.
 *
 * You should instantiate both `ApolloDebugServer` and `ApolloStore` with the same instance of this class.
 */
public class DebuggableNormalizedCache {
    weak var delegate: DebuggableNormalizedCacheDelegate?
    private let cache: NormalizedCache
    private var cachedRecords: RecordSet
    private let recordLock = NSRecursiveLock()

    /**
     * Initializes the receiver with the underlying cache object.
     *
     * - Parameter cache: The underlying cache.
     */
    public init(cache: NormalizedCache) {
        self.cache = cache
        self.cachedRecords = RecordSet()
    }

    func extract() -> [String: Any] {
        return cachedRecords.storage
    }

    private func notifyRecordChange() {
        delegate?.normalizedCache(self, didChangeRecords: self.cachedRecords)
    }
}

// MARK: NormalizedCache

extension DebuggableNormalizedCache: NormalizedCache {
    public func loadRecords(forKeys keys: [CacheKey], callbackQueue: DispatchQueue?, completion: @escaping (Result<[Record?], Error>) -> Void) {
        cache.loadRecords(forKeys: keys, callbackQueue: callbackQueue, completion: completion)
    }

    public func merge(records: RecordSet, callbackQueue: DispatchQueue?, completion: @escaping (Result<Set<CacheKey>, Error>) -> Void) {
        recordLock.lock()
        cachedRecords.merge(records: records)
        notifyRecordChange()
        recordLock.unlock()
        cache.merge(records: records, callbackQueue: callbackQueue, completion: completion)
    }

    public func clear(callbackQueue: DispatchQueue?, completion: ((Result<Void, Error>) -> Void)?) {
        recordLock.lock()
        cachedRecords.clear()
        notifyRecordChange()
        recordLock.unlock()
        cache.clear(callbackQueue: callbackQueue, completion: completion)
    }

    public func clearImmediately() throws {
        recordLock.lock()
        cachedRecords.clear()
        notifyRecordChange()
        recordLock.unlock()
        try cache.clearImmediately()
    }
}
