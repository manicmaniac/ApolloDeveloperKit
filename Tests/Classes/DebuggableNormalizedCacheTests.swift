//
//  DebuggableNormalizedCacheTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/28/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import XCTest
@testable import ApolloDeveloperKit

class DebuggableNormalizedCacheTests: XCTestCase {
    private var underlyingCache: NormalizedCache!

    override func setUp() {
        super.setUp()
        underlyingCache = InMemoryNormalizedCache()
    }

    func testLoadRecords() throws {
        let cache = DebuggableNormalizedCache(cache: underlyingCache)
        try XCTContext.runActivity(named: "when underlying cache is empty") { _ in
            let records = try cache.loadRecords(forKeys: ["foo"]).await()
            XCTAssertEqual(records.count, 1)
            XCTAssertEqual(records.compactMap { $0 }.count, 0)
        }
        try XCTContext.runActivity(named: "when underlying cache is not empty") { _ in
            let cachedFields: Record.Fields = ["bar": "baz"]
            let cachedRecords: RecordSet = ["foo": cachedFields]
            _ = try underlyingCache.merge(records: cachedRecords).await()
            let records = try cache.loadRecords(forKeys: ["foo"]).await()
            XCTAssertEqual(records.count, 1)
            let cachedRecord = Record(key: "foo", cachedFields)
            XCTAssertEqual(records.first??.key, cachedRecord.key)
        }
    }

    func testMerge() throws {
        let cache = DebuggableNormalizedCache(cache: underlyingCache)
        let fields: Record.Fields = ["bar": "baz"]
        let records: RecordSet = ["foo": fields]
        let cacheKeys = try cache.merge(records: records).await()
        XCTAssertEqual(cacheKeys, ["foo.bar"])
    }

    func testClear() throws {
        let cache = DebuggableNormalizedCache(cache: underlyingCache)
        let cachedFields: Record.Fields = ["bar": "baz"]
        let cachedRecords: RecordSet = ["foo": cachedFields]
        let cacheKeys = try cache.merge(records: cachedRecords).await()
        try cache.clear().await()
        let records = try cache.loadRecords(forKeys: Array(cacheKeys)).await()
        XCTAssertEqual(records.compactMap { $0 }.count, 0)
    }

    func testExtract() throws {
        let cache = DebuggableNormalizedCache(cache: underlyingCache)
        let cachedFields: Record.Fields = ["bar": "baz"]
        let cachedRecords: RecordSet = ["foo": cachedFields]
        _ = try cache.merge(records: cachedRecords).await()
        let storage = cache.extract()
        XCTAssertEqual(storage.count, 1)
    }
}
