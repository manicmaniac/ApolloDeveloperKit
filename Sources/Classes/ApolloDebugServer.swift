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
    private var streamResponseCompletionBlock: GCDWebServerBodyReaderCompletionBlock?

    public init(cache: DebuggableInMemoryNormalizedCache, networkTransport: DebuggableNetworkTransport) {
        self.cache = cache
        self.networkTransport = networkTransport
        self.server = GCDWebServer()
        cache.delegate = self
        networkTransport.delegate = self
        let documentRootPath = Bundle(for: type(of: self)).path(forResource: "Assets", ofType: nil)!
        server.addGETHandler(forBasePath: "/", directoryPath: documentRootPath, indexFilename: "index.html", cacheAge: 0, allowRangeRequests: false)
        server.addHandler(forMethod: "GET", path: "/events", request: GCDWebServerRequest.self) { request in
            GCDWebServerStreamedResponse(contentType: "text/event-stream", asyncStreamBlock: { [weak self] completion in
                guard let self = self else {
                    return completion(Data(), nil) // finish event stream
                }
                if self.streamResponseCompletionBlock == nil {
                    self.streamResponseCompletionBlock = completion
                    self.sendCurrentStateAsEvent()
                } else {
                    self.streamResponseCompletionBlock = completion
                }
            })
        }
    }

    deinit {
        stop()
    }

    public func start(port: UInt) {
        server.start(withPort: port, bonjourName: nil)
    }

    public func stop() {
        streamResponseCompletionBlock = nil
        server.stop()
    }

    private func sendCurrentStateAsEvent() {
        var chunk = try! JSONSerialization.data(withJSONObject: [
            "action": [:],
            "state": [
                "queries": queryManager.queryStore.store.jsonValue,
                "mutations": queryManager.mutationStore.store.jsonValue
            ],
            "dataWithOptimisticResults": cache.extract().jsonValue
        ], options: [])
        chunk.insert(contentsOf: "data: ".data(using: .utf8)!, at: 0)
        chunk.append(contentsOf: "\n\n".data(using: .utf8)!)
        streamResponseCompletionBlock?(chunk, nil)
    }

    // MARK: - DebuggableInMemoryNormalizedCacheDelegate

    func normalizedCache(_ normalizedCache: DebuggableInMemoryNormalizedCache, didChangeRecords records: RecordSet) {
        sendCurrentStateAsEvent()
    }

    // MARK: - DebuggableHTTPNetworkTransportDelegate

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation) where Operation : GraphQLOperation {
        queryManager.networkTransport(networkTransport, willSendOperation: operation)
        sendCurrentStateAsEvent()
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, response: GraphQLResponse<Operation>?, error: Error?) where Operation : GraphQLOperation {
        queryManager.networkTransport(networkTransport, didSendOperation: operation, response: response, error: error)
        sendCurrentStateAsEvent()
    }
}
