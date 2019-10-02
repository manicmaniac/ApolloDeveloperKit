//
//  ApolloDebugServer.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/15/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

/**
 * `ApolloDebugServer` is a HTTP server to communicate with `apollo-cient-devtools`.
 *
 * The server works even after the app moves to the background for a while.
 * When the server is released, it stops itself automatically.
 */
public class ApolloDebugServer {
    private let server: HTTPServer
    private let networkTransport: DebuggableNetworkTransport
    private let cache: DebuggableNormalizedCache
    private let keepAliveInterval: TimeInterval
    private let queryManager = QueryManager()
    private var eventStreamConnections = NSHashTable<HTTPConnection>()
    private weak var timer: Timer?

    /**
     * A Boolean value indicating whether the server is running or not.
     */
    public var isRunning: Bool {
        return server.isRunning
    }

    /**
     * The URL where the server is established.
     */
    public var serverURL: URL? {
        return server.serverURL
    }

    /**
     * Initializes `ApolloDebugServer` instance.
     *
     * - Parameter networkTransport: An underlying network transport object.
     * - Parameter cache: An underlying cache object.
     */
    public convenience init(networkTransport: DebuggableNetworkTransport, cache: DebuggableNormalizedCache) {
        self.init(networkTransport: networkTransport, cache: cache, keepAliveInterval: 30.0)
    }

    init(networkTransport: DebuggableNetworkTransport, cache: DebuggableNormalizedCache, keepAliveInterval: TimeInterval) {
        self.networkTransport = networkTransport
        self.cache = cache
        self.server = HTTPServer()
        self.keepAliveInterval = keepAliveInterval
        self.server.requestHandler = self
        cache.delegate = self
        networkTransport.delegate = self
    }

    deinit {
        stop()
    }

    /**
     * Starts HTTP server listening on the given port.
     *
     * This method should be invoked on the main thread.
     * The server automatically stops and restarts when it's already running.
     *
     * - Parameter port: A port number. Avoid using well-known ports.
     * - Throws: `HTTPServerError` when an error occured while setting up a socket.
     */
    public func start(port: UInt16) throws {
        stop()
        try server.start(port: port)
        scheduleTimer()
    }

    public func start<T: Collection>(randomPortIn ports: T) throws -> UInt16 where T.Element == UInt16 {
        let port = try server.start(randomPortIn: ports)
        scheduleTimer()
        return port
    }

    /**
     * Stops the server from running.
     *
     * This method should be invoked on the main thread.
     * It's safe if you invoke this method even while the server isn't running.
     */
    public func stop() {
        if isRunning {
            timer?.invalidate()
            server.stop()
        }
    }

    @objc private func timerDidFire(_ timer: Timer) {
        let ping = EventStreamChunk(rawData: Data([0x3A]))
        for connection in eventStreamConnections.allObjects {
            connection.write(ping.data)
        }
    }

    private func scheduleTimer() {
        precondition(timer?.isValid != true)
        timer = Timer.scheduledTimer(timeInterval: keepAliveInterval, target: self, selector: #selector(timerDidFire(_:)), userInfo: nil, repeats: true)
    }

    private func chunkForCurrentState() -> EventStreamChunk {
        var rawData = try! JSONSerialization.data(withJSONObject: [
            "action": [:],
            "state": [
                "queries": queryManager.queryStore.store.jsonValue,
                "mutations": queryManager.mutationStore.store.jsonValue
            ],
            "dataWithOptimisticResults": cache.extract().jsonValue
            ], options: [])
        rawData.insert(contentsOf: "data: ".data(using: .utf8)!, at: 0)
        rawData.append(contentsOf: "\n\n".data(using: .utf8)!)
        return EventStreamChunk(rawData: rawData)
    }
}

// MARK: - HTTPRequestHandler

extension ApolloDebugServer: HTTPRequestHandler {
    public func server(_ server: HTTPServer, didReceiveRequest request: HTTPRequest, connection: HTTPConnection) {
        switch (request.method, request.url.path) {
        case ("HEAD", "/events"):
            respondToRequestForEventSource(connection: connection, withBody: false)
        case ("GET", "/events"):
            respondToRequestForEventSource(connection: connection, withBody: true)
        case (_, "/events"):
            respondWithMethodNotAllowed(connection: connection, allowedMethods: ["HEAD", "GET"], withBody: true)
        case ("POST", "/request"):
            respondToRequestForGraphQLRequest(request, connection: connection)
        case (_, "/request"):
            respondWithMethodNotAllowed(connection: connection, allowedMethods: ["POST"], withBody: true)
        case ("HEAD", _):
            respondToRequestForDocumentRoot(request: request, connection: connection, withBody: false)
        case ("GET", _):
            respondToRequestForDocumentRoot(request: request, connection: connection, withBody: true)
        case (_, _):
            respondWithMethodNotAllowed(connection: connection, allowedMethods: ["HEAD", "GET"], withBody: true)
        }
    }

    private func respondWithHTTPURLResponse(connection: HTTPConnection, httpURLResponse: HTTPURLResponse, body: Data?) {
        let response = HTTPResponse(httpURLResponse: httpURLResponse, body: body, httpVersion: server.httpVersion)
        let data = response.serialize()!
        connection.write(data)
        connection.close()
    }

    private func respondWithOK(connection: HTTPConnection, contentType: MimeType?, body: Data?, contentLength: Int? = nil) {
        let response = HTTPResponse(statusCode: 200, httpVersion: server.httpVersion)
        response.setDateHeaderField()
        if let contentType = contentType {
            response.setContentTypeHeaderField(contentType)
        }
        if let body = body {
            response.setBody(body)
        }
        response.setContentLengthHeaderField(contentLength ?? body?.count ?? 0)
        let data = response.serialize()!
        connection.write(data)
        connection.close()
    }

    private func respondWithError(for statusCode: Int, connection: HTTPConnection, withDefaultBody: Bool) {
        let response = HTTPResponse.errorResponse(for: statusCode, httpVersion: server.httpVersion, withDefaultBody: withDefaultBody)
        let data = response.serialize()!
        connection.write(data)
        connection.close()
    }

    private func respondWithError(for statusCode: Int, connection: HTTPConnection, body: Data?) {
        guard let body = body else {
            return respondWithError(for: statusCode, connection: connection, withDefaultBody: true)
        }
        let response = HTTPResponse.errorResponse(for: statusCode, httpVersion: server.httpVersion, body: body)
        let data = response.serialize()!
        connection.write(data)
        connection.close()
    }

    private func respondWithBadRequest(connection: HTTPConnection, jsError: JSError) {
        let body = try? JSONSerializationFormat.serialize(value: jsError)
        respondWithError(for: 400, connection: connection, body: body)
    }

    private func respondWithMethodNotAllowed(connection: HTTPConnection, allowedMethods: [String], withBody: Bool) {
        let statusCode = 405
        let response = HTTPResponse(statusCode: statusCode, httpVersion: server.httpVersion)
        response.setDateHeaderField()
        response.setContentTypeHeaderField(.plainText(.utf8))
        response.setValue(allowedMethods.joined(separator: ", "), forHTTPHeaderField: "Allow")
        let bodyString = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n"
        let bodyData = bodyString.data(using: .utf8)!
        response.setContentLengthHeaderField(bodyData.count)
        if withBody {
            response.setBody(bodyData)
        }
        let data = response.serialize()!
        connection.write(data)
        connection.close()
    }

    private func respondToRequestForEventSource(connection: HTTPConnection, withBody: Bool) {
        let response = HTTPResponse(statusCode: 200, httpVersion: server.httpVersion)
        response.setDateHeaderField()
        response.setContentTypeHeaderField(.eventStream)
        response.setValue("chunked", forHTTPHeaderField: "Transfer-Encoding")
        if withBody {
            response.setBody(Data())
        }
        let data = response.serialize()!
        connection.write(data)
        if withBody {
            connection.write(chunkForCurrentState().data)
            eventStreamConnections.add(connection)
        } else {
            connection.close()
        }
    }

    private func respondToRequestForDocumentRoot(request: HTTPRequest, connection: HTTPConnection, withBody: Bool) {
        var documentURL = Bundle(for: type(of: self)).url(forResource: "Assets", withExtension: nil)!
        documentURL.appendPathComponent(request.url.path)
        do {
            var resourceValues = try documentURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            if resourceValues.isDirectory! {
                documentURL.appendPathComponent("index.html")
                resourceValues = try documentURL.resourceValues(forKeys: [.fileSizeKey])
            }
            let contentType = MimeType(pathExtension: documentURL.pathExtension, encoding: .utf8)
            let body = withBody ? try Data(contentsOf: documentURL) : nil
            let contentLength = resourceValues.fileSize!
            respondWithOK(connection: connection, contentType: contentType, body: body, contentLength: contentLength)
        } catch CocoaError.fileReadNoSuchFile {
            respondWithError(for: 404, connection: connection, withDefaultBody: withBody)
        } catch let error {
            let body = error.localizedDescription.data(using: .utf8)
            respondWithError(for: 500, connection: connection, body: body)
        }
    }

    private func respondToRequestForGraphQLRequest(_ request: HTTPRequest, connection: HTTPConnection) {
        guard request.value(forHTTPHeaderField: "Content-Length") != nil else {
            return respondWithError(for: 411, connection: connection, withDefaultBody: false)
        }
        guard let body = request.body else {
            return respondWithError(for: 400, connection: connection, withDefaultBody: true)
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: body, options: [])
            let operation = try GraphQLRequest(jsonObject: jsonObject)
            _ = networkTransport.send(operation: operation) { [weak self] graphQLResponse, error in
                guard let self = self else { return }
                do {
                    if let error = error {
                        throw error
                    }
                    guard let graphQLResponse = graphQLResponse else { fatalError("response must exist when error is nil") }
                    // Cannot use JSONSerializationFormat.serialize(value:) here because
                    // response.body may contain an Objective-C type like `NSString`,
                    // that is not convertible to JSONValue directly.
                    let body = try JSONSerialization.data(withJSONObject: graphQLResponse.body, options: [])
                    self.respondWithOK(connection: connection, contentType: .json, body: body)
                } catch let error as GraphQLHTTPResponseError {
                    self.respondWithHTTPURLResponse(connection: connection, httpURLResponse: error.response, body: error.body)
                } catch let error {
                    self.respondWithBadRequest(connection: connection, jsError: JSError(error))
                }
            }
        } catch let error {
            respondWithBadRequest(connection: connection, jsError: JSError(error))
        }
    }
}

// MARK: - DebuggableNormalizedCacheDelegate

extension ApolloDebugServer: DebuggableNormalizedCacheDelegate {
    func normalizedCache(_ normalizedCache: DebuggableNormalizedCache, didChangeRecords records: RecordSet) {
        for connection in eventStreamConnections.allObjects {
            connection.write(chunkForCurrentState().data)
        }
    }
}

// MARK: - DebuggableNetworkTransportDelegate

extension ApolloDebugServer: DebuggableNetworkTransportDelegate {
    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation) where Operation: GraphQLOperation {
        if !(operation is GraphQLRequest) {
            queryManager.networkTransport(networkTransport, willSendOperation: operation)
            for connection in eventStreamConnections.allObjects {
                connection.write(chunkForCurrentState().data)
            }
        }
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, response: GraphQLResponse<Operation>?, error: Error?) where Operation: GraphQLOperation {
        if !(operation is GraphQLRequest) {
            queryManager.networkTransport(networkTransport, didSendOperation: operation, response: response, error: error)
            for connection in eventStreamConnections.allObjects {
                connection.write(chunkForCurrentState().data)
            }
        }
    }
}
