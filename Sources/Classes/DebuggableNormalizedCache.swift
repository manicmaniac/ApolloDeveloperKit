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

/*
 * Since Apollo 0.16.0 `Promise` type has gone.
 * It is big breaking change for `NormalizedCache` but to support older versions, I've introduced 2 kinds of solutions.
 *
 * 1. Use generic type `T` in order not to refer to `Promise` type
 * 2. Use dynamic typing with `as Any as! ExpectedType` to follow the change of method signatures.
 *
 * These solutions are dirty but it indeed works well.
 *
 * - SeeAlso: https://github.com/apollographql/apollo-ios/releases/tag/0.16.0
 */
extension DebuggableNormalizedCache: NormalizedCache {
    public func loadRecords<T>(forKeys keys: [CacheKey]) -> T {
        let loadRecordsMethod = cache.loadRecords as Any as! ([CacheKey]) -> T
        return loadRecordsMethod(keys)
    }

    public func merge<T>(records: RecordSet) -> T {
        cachedRecords.merge(records: records)
        notifyRecordChange()
        let mergeMethod = cache.merge as Any as! (RecordSet) -> T
        return mergeMethod(records)
    }

    public func clear<T>() -> T {
        cachedRecords.clear()
        notifyRecordChange()
        let clearMethod = cache.clear as Any as! () -> T
        return clearMethod()
    }

    #if swift(>=5)
    public func loadRecords(forKeys keys: [CacheKey], callbackQueue: DispatchQueue?, completion: @escaping (Swift.Result<[Record?], Error>) -> Void) {
        let loadRecordsMethod = cache.loadRecords as Any as! ([CacheKey], DispatchQueue?, @escaping (Swift.Result<[Record?], Error>) -> Void) -> Void
        loadRecordsMethod(keys, callbackQueue, completion)
    }

    public func merge(records: RecordSet, callbackQueue: DispatchQueue?, completion: @escaping (Swift.Result<Set<CacheKey>, Error>) -> Void) {
        cachedRecords.merge(records: records)
        notifyRecordChange()
        let mergeMethod = cache.merge as Any as! (RecordSet, DispatchQueue?, @escaping (Swift.Result<Set<CacheKey>, Error>) -> Void) -> Void
        mergeMethod(records, callbackQueue, completion)
    }

    public func clear(callbackQueue: DispatchQueue?, completion: ((Swift.Result<Void, Error>) -> Void)?) {
        cachedRecords.clear()
        notifyRecordChange()
        let clearMethod = cache.clear as Any as! (DispatchQueue?, ((Swift.Result<Void, Error>) -> Void)?) -> Void
        clearMethod(callbackQueue, completion)
    }
    #endif
}
