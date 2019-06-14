//
//  DebuggableInMemoryNormalizedCache.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/15/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

protocol DebuggableInMemoryNormalizedCacheDelegate: class {
    func normalizedCache(_ normalizedCache: DebuggableInMemoryNormalizedCache, didChangeRecords records: RecordSet)
}

public final class DebuggableInMemoryNormalizedCache: NormalizedCache {
    private var records: RecordSet
    weak var delegate: DebuggableInMemoryNormalizedCacheDelegate?

    public init(records: RecordSet = RecordSet()) {
        self.records = records
    }

    public func loadRecords(forKeys keys: [CacheKey]) -> Promise<[Record?]> {
        let records = keys.map { self.records[$0] }
        return Promise(fulfilled: records)
    }

    public func merge(records: RecordSet) -> Promise<Set<CacheKey>> {
        let cacheKeys = self.records.merge(records: records)
        delegate?.normalizedCache(self, didChangeRecords: self.records)
        return Promise(fulfilled: cacheKeys)
    }

    public func clear() -> Promise<Void> {
        records.clear()
        delegate?.normalizedCache(self, didChangeRecords: records)
        return Promise(fulfilled: ())
    }

    func extract() -> [String: Any] {
        return records.storage
    }
}
