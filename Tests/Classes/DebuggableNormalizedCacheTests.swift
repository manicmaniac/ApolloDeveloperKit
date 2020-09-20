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

    func testLoadRecords_whenUnderlyingCacheIsEmpty() {
        let cache = DebuggableNormalizedCache(cache: underlyingCache)
        let expectation = self.expectation(description: "callback should be called.")
        cache.loadRecords(forKeys: ["foo"], callbackQueue: nil) { result in
            defer { expectation.fulfill() }
            switch result {
            case .success(let records):
                XCTAssertEqual(records.count, 1)
                XCTAssertEqual(records.compactMap { $0 }.count, 0)
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testLoadRecords_whenUnderlyingCacheIsNotEmpty() {
        let cache = DebuggableNormalizedCache(cache: underlyingCache)
        let cachedFields: Record.Fields = ["bar": "baz"]
        let cachedRecords: RecordSet = ["foo": cachedFields]
        let expectation = self.expectation(description: "callback should be called.")
        underlyingCache.merge(records: cachedRecords, callbackQueue: nil) { result in
            switch result {
            case .success:
                cache.loadRecords(forKeys: ["foo"], callbackQueue: nil) { result in
                    defer { expectation.fulfill() }
                    switch result {
                    case .success(let records):
                        XCTAssertEqual(records.count, 1)
                        let cachedRecord = Record(key: "foo", cachedFields)
                        XCTAssertEqual(records.first??.key, cachedRecord.key)
                    case .failure(let error):
                        XCTFail(String(describing: error))
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testMerge() {
        let cache = DebuggableNormalizedCache(cache: underlyingCache)
        let fields: Record.Fields = ["bar": "baz"]
        let records: RecordSet = ["foo": fields]
        let expectation = self.expectation(description: "callback should be called.")
        cache.merge(records: records, callbackQueue: nil) { result in
            defer { expectation.fulfill() }
            switch result {
            case .success(let cacheKeys):
                XCTAssertEqual(cacheKeys, ["foo.bar"])
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testClear() {
        let cache = DebuggableNormalizedCache(cache: underlyingCache)
        let cachedFields: Record.Fields = ["bar": "baz"]
        let cachedRecords: RecordSet = ["foo": cachedFields]
        let expectation = self.expectation(description: "callback should be called.")
        cache.merge(records: cachedRecords, callbackQueue: nil) { result in
            switch result {
            case .success(let cacheKeys):
                cache.clear(callbackQueue: nil) { result in
                    switch result {
                    case .success:
                        cache.loadRecords(forKeys: Array(cacheKeys), callbackQueue: nil) { result in
                            defer { expectation.fulfill() }
                            switch result {
                            case .success(let records):
                                XCTAssertEqual(records.compactMap { $0 }.count, 0)
                            case .failure(let error):
                                XCTFail(String(describing: error))
                            }
                        }
                    case .failure(let error):
                        XCTFail(String(describing: error))
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testClearImmediately() {
        let cache = DebuggableNormalizedCache(cache: underlyingCache)
        let cachedFields: Record.Fields = ["bar": "baz"]
        let cachedRecords: RecordSet = ["foo": cachedFields]
        let expectation = self.expectation(description: "callback should be called.")
        cache.merge(records: cachedRecords, callbackQueue: nil) { result in
            do {
                switch result {
                case .success(let cacheKeys):
                    try cache.clearImmediately()
                    cache.loadRecords(forKeys: Array(cacheKeys), callbackQueue: nil) { result in
                        defer { expectation.fulfill() }
                        switch result {
                        case .success(let records):
                            XCTAssert(records.compactMap { $0 }.isEmpty)
                        case .failure(let error):
                            XCTFail(String(describing: error))
                        }
                    }
                case .failure(let error):
                    throw error
                }
            } catch let error {
                XCTFail(String(describing: error))
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }

    func testExtract() {
        let cache = DebuggableNormalizedCache(cache: underlyingCache)
        let cachedFields: Record.Fields = ["bar": "baz"]
        let cachedRecords: RecordSet = ["foo": cachedFields]
        let expectation = self.expectation(description: "callback should be called.")
        cache.merge(records: cachedRecords, callbackQueue: nil) { result in
            defer { expectation.fulfill() }
            switch result {
            case .success:
                let storage = cache.extract()
                XCTAssertEqual(storage.count, 1)
            case .failure(let error):
                XCTFail(String(describing: error))
            }
        }
        waitForExpectations(timeout: 0.25, handler: nil)
    }
}
