//
//  ApolloDebugServer.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/15/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

// https://github.com/swisspol/GCDWebServer/issues/316
#if COCOAPODS
import GCDWebServer
#else
import GCDWebServers
#endif

public class ApolloDebugServer: DebuggableInMemoryNormalizedCacheDelegate, DebuggableNetworkTransportDelegate {
    private let server: GCDWebServer
    private let cache: DebuggableInMemoryNormalizedCache
    private let networkTransport: DebuggableNetworkTransport
    private let queryManager = QueryManager()
    private var eventStreamQueue = EventStreamQueue<GCDWebServerRequest>()

    public init(cache: DebuggableInMemoryNormalizedCache, networkTransport: DebuggableNetworkTransport) {
        self.cache = cache
        self.networkTransport = networkTransport
        self.server = GCDWebServer()
        cache.delegate = self
        networkTransport.delegate = self
        configureHandlers()
    }

    deinit {
        stop()
    }

    public func start(port: UInt) {
        server.start(withPort: port, bonjourName: nil)
    }

    public func stop() {
        server.stop()
    }

    private func configureHandlers() {
        let documentRootPath = Bundle(for: type(of: self)).path(forResource: "Assets", ofType: nil)!
        server.addGETHandler(forBasePath: "/", directoryPath: documentRootPath, indexFilename: "index.html", cacheAge: 0, allowRangeRequests: false)
        server.addHandler(forMethod: "GET", path: "/events", request: GCDWebServerRequest.self) { [weak self] request in
            guard let self = self else {
                return GCDWebServerErrorResponse(statusCode: 500)
            }
            self.eventStreamQueue.enqueue(chunk: self.chunkForCurrentState(), forKey: request)
            return GCDWebServerStreamedResponse(contentType: "text/event-stream", asyncStreamBlock: { [weak self] completion in
                while let self = self {
                    if let chunk = self.eventStreamQueue.dequeue(key: request) {
                        completion(chunk.data, chunk.error)
                        return
                    }
                }
                completion(Data(), nil) // finish event stream
            })
        }
    }

    private func chunkForCurrentState() -> EventStreamChunk {
        var data = try! JSONSerialization.data(withJSONObject: [
            "action": [:],
            "state": [
                "queries": queryManager.queryStore.store.jsonValue,
                "mutations": queryManager.mutationStore.store.jsonValue
            ],
            "dataWithOptimisticResults": cache.extract().jsonValue
            ], options: [])
        data.insert(contentsOf: "data: ".data(using: .utf8)!, at: 0)
        data.append(contentsOf: "\n\n".data(using: .utf8)!)
        return EventStreamChunk(data: data, error: nil)
    }

    // MARK: - DebuggableInMemoryNormalizedCacheDelegate

    func normalizedCache(_ normalizedCache: DebuggableInMemoryNormalizedCache, didChangeRecords records: RecordSet) {
        eventStreamQueue.enqueueForAllKeys(chunk: chunkForCurrentState())
    }

    // MARK: - DebuggableHTTPNetworkTransportDelegate

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation) where Operation : GraphQLOperation {
        queryManager.networkTransport(networkTransport, willSendOperation: operation)
        eventStreamQueue.enqueueForAllKeys(chunk: chunkForCurrentState())
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, response: GraphQLResponse<Operation>?, error: Error?) where Operation : GraphQLOperation {
        queryManager.networkTransport(networkTransport, didSendOperation: operation, response: response, error: error)
        eventStreamQueue.enqueueForAllKeys(chunk: chunkForCurrentState())
    }
}
