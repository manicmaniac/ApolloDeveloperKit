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
    private var cachedRecords: RecordSet

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
    public func loadRecords(forKeys keys: [CacheKey]) -> Promise<[Record?]> {
        return cache.loadRecords(forKeys: keys)
    }

    public func merge(records: RecordSet) -> Promise<Set<CacheKey>> {
        return cache.merge(records: records)
            .andThen { [weak self] _ in self?.cachedRecords.merge(records: records) }
            .andThen { [weak self] _ in self?.notifyRecordChange() }
    }

    public func clear() -> Promise<Void> {
        return cache.clear()
            .andThen { [weak self] in self?.cachedRecords.clear() }
            .andThen { [weak self] in self?.notifyRecordChange() }
    }
}
