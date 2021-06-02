//
//  ApolloDebugServer.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/15/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

/**
 * `ApolloDebugServer` is a HTTP server to communicate with `apollo-client-devtools`.
 *
 * The server works even after the app moves to the background for a while.
 * When the server is released, it stops itself automatically.
 */
public class ApolloDebugServer {
    private static let documentRootURL = Bundle(for: ApolloDebugServer.self).url(forResource: "Assets", withExtension: nil)!
    private let networkTransport: DebuggableNetworkTransport
    private let cache: DebuggableNormalizedCache
    private let keepAliveInterval: TimeInterval
    private let server = HTTPServer()
    private let operationStoreController = OperationStoreController(store: InMemoryOperationStore())
    private let backgroundTask = BackgroundTask()
    private let consoleRedirection = ConsoleRedirection.shared
    private var eventStreams = HTTPOutputStreamSet()
    private weak var timer: Timer?

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
        self.keepAliveInterval = keepAliveInterval
        self.server.delegate = self
        self.cache.delegate = self
        self.networkTransport.delegate = self
    }

    deinit {
        stop()
    }

    /**
     * A Boolean value indicating whether the server is running or not.
     */
    public var isRunning: Bool {
        return server.isRunning
    }

    /**
     * The URL where the server is established.
     * Only returns resolved hostname in IPv4 format.
     *
     * - Warning: If running on a simulator, `serverURL` might return `nil`.
     * Since there's no way to access host machine's network interfaces, `ApolloDebugServer` assumes `en0` or `en1` is the only available interfaces.
     * - SeeAlso: `ApolloDebugServer.serverURLs`
     */
    public var serverURL: URL? {
        return server.serverURL
    }

    /**
     * The possible URLs where the server is established.
     *
     * The hostname may contain resolved IPv4 / IPv6 format.
     */
    public var serverURLs: [URL] {
        return server.serverURLs
    }

    /**
     * Enables console redirection (disabled by default).
     *
     * When console redirection is enabled, all logs written in stdout and stderr are redirected to the web browser's console.
     * Console redirection will stop when the server is released from the memory but won't stop when the server just stops.
     *
     * - Warning: This is an experimental feature for now, so please do not rely on the behavior.
     */
    public var enableConsoleRedirection = false {
        didSet {
            if enableConsoleRedirection {
                consoleRedirection.addObserver(self, selector: #selector(didReceiveConsoleDidWriteNotification(_:)))
            } else {
                consoleRedirection.removeObserver(self)
            }
        }
    }

    /**
     * Starts HTTP server listening on the given port.
     *
     * This method should be invoked on the main thread.
     * The server automatically stops and restarts when it's already running.
     *
     * - Parameter port: A port number. Avoid using well-known ports.
     * - Throws: `POSIXError` when an error occurred while setting up a socket.
     */
    public func start(port: UInt16) throws {
        precondition(Thread.isMainThread)
        stop()
        try server.start(port: port)
        scheduleTimer()
    }

    /**
     * Starts HTTP server listening on a random port in the given range.
     *
     * This method should be invoked on the main thread.
     *
     * - Parameter ports: A range of ports. Avoid using well-known ports.
     * - Throws: `HTTPServerError` when an error occurred while setting up a socket.     *
     */
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
        precondition(Thread.isMainThread)
        if isRunning {
            timer?.invalidate()
            server.stop()
        }
    }

    @objc private func timerDidFire(_ timer: Timer) {
        let ping = HTTPChunkedResponse(event: EventStreamMessage.ping)
        eventStreams.broadcast(data: ping.data)
    }

    private func scheduleTimer() {
        precondition(timer?.isValid != true)
        timer = Timer.scheduledTimer(timeInterval: keepAliveInterval, target: self, selector: #selector(timerDidFire(_:)), userInfo: nil, repeats: true)
    }

    private func chunkForCurrentState() -> HTTPChunkedResponse {
        let stateChange = StateChange(dataWithOptimisticResults: cache.extract(), state: operationStoreController.store.state)
        return HTTPChunkedResponse(event: stateChange)
    }

    private func eventType(for destination: ConsoleRedirection.Destination) -> ConsoleEventType {
        switch destination {
        case .standardOutput:
            return .stdout
        case .standardError:
            return .stderr
        }
    }

    /**
     * DO NOT invoke this method directly.
     * It is only visible for testing purpose.
     */
    @objc func didReceiveConsoleDidWriteNotification(_ notification: Notification) {
        guard let notification = ConsoleDidWriteNotification(rawValue: notification),
            notification.object === ConsoleRedirection.shared,
            let message = String(data: notification.data, encoding: .utf8) else { return }
        let event = ConsoleEvent(data: message, type: eventType(for: notification.destination))
        let chunk = HTTPChunkedResponse(event: event)
        eventStreams.broadcast(data: chunk.data)
    }
}

// MARK: HTTPServerDelegate

extension ApolloDebugServer: HTTPServerDelegate {
    func server(_ server: HTTPServer, didStartListeningTo port: UInt16) {
        backgroundTask.beginBackgroundTaskIfPossible()
    }

    func server(_ server: HTTPServer, didReceiveRequest context: HTTPRequestContext) {
        switch (context.requestMethod, context.requestURL.path) {
        case ("HEAD", "/events"):
            respondEventSource(context, withBody: false)
        case ("GET", "/events"):
            respondEventSource(context, withBody: true)
        case (_, "/events"):
            respondMethodNotAllowed(context, allowedMethods: ["HEAD", "GET"], withBody: true)
        case ("POST", "/request"):
            respondGraphQLRequest(context)
        case (_, "/request"):
            respondMethodNotAllowed(context, allowedMethods: ["POST"], withBody: true)
        case ("HEAD", _):
            context.respondDocument(rootURL: ApolloDebugServer.documentRootURL, withBody: false)
        case ("GET", _):
            context.respondDocument(rootURL: ApolloDebugServer.documentRootURL, withBody: true)
        case (_, _):
            respondMethodNotAllowed(context, allowedMethods: ["HEAD", "GET"], withBody: true)
        }
    }

    func server(_ server: HTTPServer, didFailToHandle context: HTTPRequestContext, error: Error) {
        if case HTTPServerError.unsupportedBodyEncoding = error {
            return context.respondError(statusCode: 415, withBody: true)
        }
        let body = Data(error.localizedDescription.utf8)
        context.respondError(statusCode: 500, contentType: .plainText(.utf8), body: body)
    }

    private func respondBadRequest(_ context: HTTPRequestContext, jsError: ErrorLike) {
        let body = try! JSONSerializationFormat.serialize(value: jsError)
        context.respondError(statusCode: 400, contentType: .json, body: body)
    }

    private func respondMethodNotAllowed(_ context: HTTPRequestContext, allowedMethods: [String], withBody: Bool) {
        let statusCode = 405
        let body = withBody ? Data("\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n".utf8) : nil
        context.setContentLength(body?.count ?? 0)
        context.setContentType(.plainText(.utf8))
        context.setValue(allowedMethods.joined(separator: ", "), forResponse: "Allow")
        let stream = context.respond(statusCode: statusCode)
        if let body = body {
            stream.write(data: body)
        }
        stream.close()
    }

    private func respondEventSource(_ context: HTTPRequestContext, withBody: Bool) {
        let stream = context.respondEventSource()
        if withBody {
            let chunk = chunkForCurrentState()
            stream.write(data: chunk.data)
            eventStreams.insert(stream)
        } else {
            stream.close()
        }
    }

    private func respondGraphQLRequest(_ context: HTTPRequestContext) {
        guard context.value(forRequest: "Content-Length") != nil else {
            return context.respondError(statusCode: 411, withBody: false)
        }
        guard let body = context.requestBody else {
            return context.respondError(statusCode: 400, withBody: true)
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: body)
            let operationJSONObject = try Operation(jsonValue: jsonObject)
            let operation = AnyGraphQLOperation(operation: operationJSONObject)
            _ = networkTransport.send(operation: operation, cachePolicy: .fetchIgnoringCacheCompletely, contextIdentifier: nil, callbackQueue: .global()) { [weak self] result in
                guard let self = self else { return }
                do {
                    let graphQLResult = try result.get()
                    let body = try JSONSerialization.data(withJSONObject: graphQLResult.jsonValue)
                    context.respondJSONData(body)
                } catch ResponseCodeInterceptor.ResponseCodeError.invalidResponseCode(let response?, let rawData) {
                    let stream = context.respond(proxying: response)
                    if let rawData = rawData {
                        stream.write(data: rawData)
                    }
                    stream.close()
                } catch let error {
                    self.respondBadRequest(context, jsError: ErrorLike(error: error))
                }
            }
        } catch let error {
            respondBadRequest(context, jsError: ErrorLike(error: error))
        }
    }
}

// MARK: DebuggableNormalizedCacheDelegate

extension ApolloDebugServer: DebuggableNormalizedCacheDelegate {
    func normalizedCache(_ normalizedCache: DebuggableNormalizedCache, didChangeRecords records: RecordSet) {
        let chunk = chunkForCurrentState()
        eventStreams.broadcast(data: chunk.data)
    }
}

// MARK: DebuggableNetworkTransportDelegate

extension ApolloDebugServer: DebuggableNetworkTransportDelegate {
    public func networkTransport<Operation>(_ networkTransport: NetworkTransport, willSendOperation operation: Operation) where Operation: GraphQLOperation {
        if operation is AnyGraphQLOperation { return }
        operationStoreController.networkTransport(networkTransport, willSendOperation: operation)
        let chunk = chunkForCurrentState()
        eventStreams.broadcast(data: chunk.data)
    }

    public func networkTransport<Operation>(_ networkTransport: NetworkTransport, didSendOperation operation: Operation, result: Result<GraphQLResult<Operation.Data>, Error>) where Operation: GraphQLOperation {
        if operation is AnyGraphQLOperation { return }
        operationStoreController.networkTransport(networkTransport, didSendOperation: operation, result: result)
        let chunk = chunkForCurrentState()
        eventStreams.broadcast(data: chunk.data)
    }
}
