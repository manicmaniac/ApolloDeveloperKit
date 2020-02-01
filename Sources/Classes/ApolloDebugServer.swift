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
    private let queryManager = QueryManager()
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
        let ping = HTTPChunkedResponse(string: ":\n\n")
        for connection in eventStreamConnections.allObjects {
            connection.write(chunkedResponse: ping)
        }
    }

    private func scheduleTimer() {
        precondition(timer?.isValid != true)
        timer = Timer.scheduledTimer(timeInterval: keepAliveInterval, target: self, selector: #selector(timerDidFire(_:)), userInfo: nil, repeats: true)
    }

    private func chunkForCurrentState() -> HTTPChunkedResponse {
        var rawData = try! JSONSerialization.data(withJSONObject: [
            "state": [
                "queries": queryManager.queryStore.store.jsonValue,
                "mutations": queryManager.mutationStore.store.jsonValue
            ],
            "dataWithOptimisticResults": cache.extract().jsonValue
            ], options: [])
        rawData.insert(contentsOf: "data: ".data(using: .utf8)!, at: 0)
        rawData.append(contentsOf: "\n\n".data(using: .utf8)!)
        return HTTPChunkedResponse(rawData: rawData)
    }

    private func eventName(for destination: ConsoleRedirection.Destination) -> String {
        switch destination {
        case .standardOutput:
            return "stdout"
        case .standardError:
            return "stderr"
        }
    }

    /**
     * DO NOT invoke this method directly.
     * It is only visible for testing purpose.
     */
    @objc func didReceiveConsoleDidWriteNotification(_ notification: Notification) {
        guard notification.object as? ConsoleRedirection === ConsoleRedirection.shared else { return }
        let data = notification.userInfo![consoleDataKey] as! Data
        let destination = notification.userInfo![consoleDestinationKey] as! ConsoleRedirection.Destination
        guard let message = String(data: data, encoding: .utf8) else { return }
        let envelopedMessage = "data: " + message.replacingOccurrences(of: "\n", with: "\ndata: ")
        let payload = "event: \(eventName(for: destination))\n\(envelopedMessage)\n\n"
        let chunk = HTTPChunkedResponse(string: payload)
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
        let body = withDefaultBody ? "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n".data(using: .utf8) : nil
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

    private func respondBadRequest(to request: URLRequest, in connection: HTTPConnection, jsError: JSError) {
        let body = try? JSONSerializationFormat.serialize(value: jsError)
        respondError(to: request, in: connection, statusCode: 400, with: body)
    }

    private func respondMethodNotAllowed(to request: URLRequest, in connection: HTTPConnection, allowedMethods: [String], withBody: Bool) {
        let statusCode = 405
        let body = withBody ? "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n".data(using: .utf8) : nil
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
            let body = error.localizedDescription.data(using: .utf8)
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
            let jsonObject = try JSONSerialization.jsonObject(with: body, options: [])
            let operation = try GraphQLRequest(jsonValue: jsonObject)
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
                    self.respond(to: request, in: connection, contentType: .json, contentLength: nil, body: body)
                } catch let error as GraphQLHTTPResponseError {
                    connection.write(response: error.response, body: error.body)
                    connection.close()
                } catch let error {
                    self.respondBadRequest(to: request, in: connection, jsError: JSError(error))
                }
            }
        } catch let error {
            respondBadRequest(to: request, in: connection, jsError: JSError(error))
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
        if operation is GraphQLRequest { return }
        queryManager.networkTransport(networkTransport, willSendOperation: operation)
        let chunk = chunkForCurrentState()
        for connection in eventStreamConnections.allObjects {
            connection.write(chunkedResponse: chunk)
        }
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, response: GraphQLResponse<Operation>?, error: Error?) where Operation: GraphQLOperation {
        if operation is GraphQLRequest { return }
        queryManager.networkTransport(networkTransport, didSendOperation: operation, response: response, error: error)
        let chunk = chunkForCurrentState()
        for connection in eventStreamConnections.allObjects {
            connection.write(chunkedResponse: chunk)
        }
    }
}
