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
    private let server: HTTPServer
    private let networkTransport: DebuggableNetworkTransport
    private let cache: DebuggableNormalizedCache
    private let keepAliveInterval: TimeInterval
    private let dateFormatter = DateFormatter()
    private let operationStoreController = OperationStoreController(store: InMemoryOperationStore())
    private let backgroundTask = BackgroundTask()
    private var eventStreamConnections = NSHashTable<HTTPConnection>.weakObjects()
    private weak var timer: Timer?

    /**
     * A Boolean value indicating whether the server is running or not.
     */
    public var isRunning: Bool {
        return server.isRunning
    }

    /**
     * The URL where the server is established.
     *
     * - Warning: If running on a simulator, `serverURL` might return `nil`.
     * Since there's no way to access host machine's network interfaces, `ApolloDebugServer` assumes `en0` or `en1` is the only available interfaces.
     */
    public var serverURL: URL? {
        return server.serverURL
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
                ConsoleRedirection.shared.addObserver(self, selector: #selector(didReceiveConsoleDidWriteNotification(_:)))
            } else {
                ConsoleRedirection.shared.removeObserver(self)
            }
        }
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
        self.dateFormatter.locale = Locale(identifier: "en_US")
        self.dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.dateFormatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
        self.server.delegate = self
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
        for connection in eventStreamConnections.allObjects {
            connection.write(chunkedResponse: ping)
        }
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
        for connection in eventStreamConnections.allObjects {
            connection.write(chunkedResponse: chunk)
        }
    }
}

// MARK: HTTPRequestHandler

extension ApolloDebugServer: HTTPServerDelegate {
    func server(_ server: HTTPServer, didStartListeningTo port: UInt16) {
        backgroundTask.beginBackgroundTaskIfPossible()
    }

    func server(_ server: HTTPServer, didReceiveRequest request: URLRequest, connection: HTTPConnection) {
        guard let path = request.url?.path else {
            return
        }
        switch (request.httpMethod, path) {
        case ("HEAD", "/events"):
            respondEventSource(to: request, in: connection, withBody: false)
        case ("GET", "/events"):
            respondEventSource(to: request, in: connection, withBody: true)
        case (_, "/events"):
            respondMethodNotAllowed(to: request, in: connection, allowedMethods: ["HEAD", "GET"], withBody: true)
        case ("POST", "/request"):
            respondToRequestForGraphQLRequest(request, connection: connection)
        case (_, "/request"):
            respondMethodNotAllowed(to: request, in: connection, allowedMethods: ["POST"], withBody: true)
        case ("HEAD", _):
            respondDocument(to: request, connection: connection, withBody: false)
        case ("GET", _):
            respondDocument(to: request, connection: connection, withBody: true)
        case (_, _):
            respondMethodNotAllowed(to: request, in: connection, allowedMethods: ["HEAD", "GET"], withBody: true)
        }
    }

    func server(_ server: HTTPServer, didFailToHandle request: URLRequest, connection: HTTPConnection, error: Error) {
        respondError(to: request, in: connection, statusCode: 500, with: Data(error.localizedDescription.utf8))
    }

    private func respond(to request: URLRequest, in connection: HTTPConnection, contentType: MIMEType?, contentLength: Int?, body: Data?) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: connection.httpVersion, headerFields: [
            "Content-Length": String(contentLength ?? body?.count ?? 0),
            "Content-Type": String(describing: contentType ?? .octetStream),
            "Date": dateFormatter.string(from: Date())
        ])!
        connection.write(response: response, body: body)
        connection.close()
    }

    private func respondError(to request: URLRequest, in connection: HTTPConnection, statusCode: Int, withDefaultBody: Bool) {
        let body = withDefaultBody ? Data("\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n".utf8) : nil
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: connection.httpVersion, headerFields: [
            "Content-Length": String(body?.count ?? 0),
            "Content-Type": "text/plain; charset=utf-8",
            "Date": dateFormatter.string(from: Date())
        ])!
        connection.write(response: response, body: body)
        connection.close()
    }

    private func respondError(to request: URLRequest, in connection: HTTPConnection, statusCode: Int, with body: Data?) {
        guard let body = body else {
            return respondError(to: request, in: connection, statusCode: statusCode, withDefaultBody: true)
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: connection.httpVersion, headerFields: [
            "Content-Length": String(body.count),
            "Content-Type": "text/plain; charset=utf-8",
            "Date": dateFormatter.string(from: Date())
        ])!
        connection.write(response: response, body: body)
        connection.close()
    }

    private func respondBadRequest(to request: URLRequest, in connection: HTTPConnection, jsError: ErrorLike) {
        let body = try? JSONSerializationFormat.serialize(value: jsError)
        respondError(to: request, in: connection, statusCode: 400, with: body)
    }

    private func respondMethodNotAllowed(to request: URLRequest, in connection: HTTPConnection, allowedMethods: [String], withBody: Bool) {
        let statusCode = 405
        let body = withBody ? Data("\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n".utf8) : nil
        let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: connection.httpVersion, headerFields: [
            "Allow": allowedMethods.joined(separator: ", "),
            "Content-Length": String(body?.count ?? 0),
            "Content-Type": "text/plain; charset=utf-8",
            "Date": dateFormatter.string(from: Date())
        ])!
        connection.write(response: response, body: body)
        connection.close()
    }

    private func respondEventSource(to request: URLRequest, in connection: HTTPConnection, withBody: Bool) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: connection.httpVersion, headerFields: [
            "Content-Type": "text/event-stream",
            "Date": dateFormatter.string(from: Date()),
            "Transfer-Encoding": "chunked"
        ])!
        connection.write(response: response, body: withBody ? Data() : nil)
        if withBody {
            connection.write(chunkedResponse: chunkForCurrentState())
            eventStreamConnections.add(connection)
        } else {
            connection.close()
        }
    }

    private func respondDocument(to request: URLRequest, connection: HTTPConnection, withBody: Bool) {
        var documentURL = Bundle(for: type(of: self)).url(forResource: "Assets", withExtension: nil)!
        if let path = request.url?.path {
            documentURL.appendPathComponent(path)
        }
        do {
            var resourceValues = try documentURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            if resourceValues.isDirectory! {
                documentURL.appendPathComponent("index.html")
                resourceValues = try documentURL.resourceValues(forKeys: [.fileSizeKey])
            }
            let contentType = MIMEType(pathExtension: documentURL.pathExtension, encoding: .utf8)
            let body = withBody ? try Data(contentsOf: documentURL) : nil
            let contentLength = resourceValues.fileSize!
            respond(to: request, in: connection, contentType: contentType, contentLength: contentLength, body: body)
        } catch CocoaError.fileReadNoSuchFile {
            respondError(to: request, in: connection, statusCode: 404, withDefaultBody: withBody)
        } catch let error {
            let body = Data(error.localizedDescription.utf8)
            respondError(to: request, in: connection, statusCode: 500, with: body)
        }
    }

    private func respondToRequestForGraphQLRequest(_ request: URLRequest, connection: HTTPConnection) {
        guard request.value(forHTTPHeaderField: "Content-Length") != nil else {
            return respondError(to: request, in: connection, statusCode: 411, withDefaultBody: false)
        }
        guard let body = request.httpBody else {
            return respondError(to: request, in: connection, statusCode: 400, withDefaultBody: true)
        }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: body)
            let operationJSONObject = try Operation(jsonValue: jsonObject)
            let operation = try AnyGraphQLOperation(operation: operationJSONObject)
            _ = networkTransport.send(operation: operation) { [weak self] result in
                guard let self = self else { return }
                do {
                    let response = try result.get()
                    // Cannot use JSONSerializationFormat.serialize(value:) here because
                    // response.body may contain an Objective-C type like `NSString`,
                    // that is not convertible to JSONValue directly.
                    let body = try JSONSerialization.data(withJSONObject: response.body)
                    self.respond(to: request, in: connection, contentType: .json, contentLength: nil, body: body)
                } catch let error as GraphQLHTTPResponseError {
                    connection.write(response: error.response, body: error.body)
                    connection.close()
                } catch let error {
                    self.respondBadRequest(to: request, in: connection, jsError: ErrorLike(error: error))
                }
            }
        } catch let error {
            respondBadRequest(to: request, in: connection, jsError: ErrorLike(error: error))
        }
    }
}

// MARK: DebuggableNormalizedCacheDelegate

extension ApolloDebugServer: DebuggableNormalizedCacheDelegate {
    func normalizedCache(_ normalizedCache: DebuggableNormalizedCache, didChangeRecords records: RecordSet) {
        let chunk = chunkForCurrentState()
        for connection in eventStreamConnections.allObjects {
            connection.write(chunkedResponse: chunk)
        }
    }
}

// MARK: DebuggableNetworkTransportDelegate

extension ApolloDebugServer: DebuggableNetworkTransportDelegate {
    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation) where Operation: GraphQLOperation {
        if operation is AnyGraphQLOperation { return }
        operationStoreController.networkTransport(networkTransport, willSendOperation: operation)
        let chunk = chunkForCurrentState()
        for connection in eventStreamConnections.allObjects {
            connection.write(chunkedResponse: chunk)
        }
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, result: Result<GraphQLResponse<Operation.Data>, Error>) where Operation: GraphQLOperation {
        if operation is AnyGraphQLOperation { return }
        operationStoreController.networkTransport(networkTransport, didSendOperation: operation, result: result)
        let chunk = chunkForCurrentState()
        for connection in eventStreamConnections.allObjects {
            connection.write(chunkedResponse: chunk)
        }
    }
}
