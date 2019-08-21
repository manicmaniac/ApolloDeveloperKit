//
//  DebuggableNormalizedCache.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/15/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

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
    private var records: RecordSet

    /**
     * Initializes the receiver with the underlying cache object.
     *
     * - Parameter cache: The underlying cache.
     */
    public init(cache: NormalizedCache) {
        self.cache = cache
        self.records = RecordSet()
    }

    func extract() -> [String: Any] {
        return records.storage
    }
}

// MARK: NormalizedCache

extension DebuggableNormalizedCache: NormalizedCache {
    public func loadRecords(forKeys keys: [CacheKey]) -> Promise<[Record?]> {
        return cache.loadRecords(forKeys: keys)
    }

    public func merge(records: RecordSet) -> Promise<Set<CacheKey>> {
        let promise = cache.merge(records: records)
        self.records.merge(records: records)
        delegate?.normalizedCache(self, didChangeRecords: self.records)
        return promise
    }

    public func clear() -> Promise<Void> {
        let promise = cache.clear()
        delegate?.normalizedCache(self, didChangeRecords: records)
        return promise
    }
}
