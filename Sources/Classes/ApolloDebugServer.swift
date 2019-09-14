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
    private let dateFormatter: CFDateFormatter
    private var eventStreamQueueMap = EventStreamQueueMap<FileHandle>()
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

        let enUSLocale = CFLocaleCreate(kCFAllocatorDefault, CFLocaleIdentifier("en_US" as CFString))
        let gmtTimeZone = CFTimeZoneCreateWithTimeIntervalFromGMT(kCFAllocatorDefault, 0)
        self.dateFormatter = CFDateFormatterCreate(kCFAllocatorDefault, enUSLocale, .noStyle, .noStyle)!
        CFDateFormatterSetProperty(self.dateFormatter, CFDateFormatterKey.timeZone.rawValue, gmtTimeZone)
        CFDateFormatterSetFormat(self.dateFormatter, "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'" as CFString)

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
        let timer = Timer(timeInterval: keepAliveInterval, target: self, selector: #selector(timerDidFire(_:)), userInfo: nil, repeats: true)
        self.timer = timer
        RunLoop.current.add(timer, forMode: .default)
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
        eventStreamQueueMap.enqueueForAllKeys(chunk: ping)
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
    public func server(_ server: HTTPServer, didReceiveRequest request: CFHTTPMessage, fileHandle: FileHandle, completion: @escaping () -> Void) {
        let method = CFHTTPMessageCopyRequestMethod(request)!.takeRetainedValue() as String
        let url = CFHTTPMessageCopyRequestURL(request)!.takeRetainedValue() as URL
        switch (method, url.path) {
        case ("HEAD", "/events"):
            respondToRequestForEventSource(request, fileHandle: fileHandle, withBody: false, completion: completion)
        case ("GET", "/events"):
            respondToRequestForEventSource(request, fileHandle: fileHandle, withBody: true, completion: completion)
        case (_, "/events"):
            respondWithMethodNotAllowed(fileHandle: fileHandle, allowedMethods: ["HEAD", "GET"], withBody: true, completion: completion)
        case ("POST", "/request"):
            respondToRequestForGraphQLRequest(request, fileHandle: fileHandle, completion: completion)
        case (_, "/request"):
            respondWithMethodNotAllowed(fileHandle: fileHandle, allowedMethods: ["POST"], withBody: true, completion: completion)
        case ("HEAD", _):
            respondToRequestForDocumentRoot(url: url, request: request, fileHandle: fileHandle, withBody: false, completion: completion)
        case ("GET", _):
            respondToRequestForDocumentRoot(url: url, request: request, fileHandle: fileHandle, withBody: true, completion: completion)
        case (_, _):
            respondWithMethodNotAllowed(fileHandle: fileHandle, allowedMethods: ["HEAD", "GET"], withBody: true, completion: completion)
        }
    }

    private func respondWithLengthRequired(fileHandle: FileHandle, completion: @escaping () -> Void) {
        let statusCode = 411
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, nil, server.httpVersion).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(response, "Date" as CFString, currentHTTPDateCFString())
        let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
        try? fileHandle.writeData(data)
        completion()
    }

    private func respondWithInternalServerError(fileHandle: FileHandle, withBody: Bool, completion: @escaping () -> Void) {
        let statusCode = 500
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, nil, server.httpVersion).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(response, "Date" as CFString, currentHTTPDateCFString())
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "text/plain; charset=utf-8" as CFString)
        let bodyString = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n"
        let bodyData = bodyString.data(using: .utf8)!
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Length" as CFString, String(bodyData.count) as CFString)
        if withBody {
            CFHTTPMessageSetBody(response, bodyData as CFData)
        }
        let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
        try? fileHandle.writeData(data)
        completion()
    }

    private func respondWithBadRequest(fileHandle: FileHandle, withBody: Bool, completion: @escaping () -> Void) {
        let statusCode = 400
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, nil, server.httpVersion).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(response, "Date" as CFString, currentHTTPDateCFString())
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "text/plain; charset=utf-8" as CFString)
        let bodyString = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n"
        let bodyData = bodyString.data(using: .utf8)!
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Length" as CFString, String(bodyData.count) as CFString)
        if withBody {
            CFHTTPMessageSetBody(response, bodyData as CFData)
        }
        let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
        try? fileHandle.writeData(data)
        completion()
    }

    private func respondWithBadRequest(fileHandle: FileHandle, jsError: JSError, completion: @escaping () -> Void) {
        let statusCode = 400
        guard let body = try? JSONSerializationFormat.serialize(value: jsError) else {
            return respondWithBadRequest(fileHandle: fileHandle, withBody: true, completion: completion)
        }
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, nil, server.httpVersion).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(response, "Date" as CFString, currentHTTPDateCFString())
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "text/plain; charset=utf-8" as CFString)
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Length" as CFString, String(body.count) as CFString)
        CFHTTPMessageSetBody(response, body as CFData)
        let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
        try? fileHandle.writeData(data)
        completion()
    }

    private func respondWithNotFound(fileHandle: FileHandle, withBody: Bool, completion: @escaping () -> Void) {
        let statusCode = 404
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, nil, server.httpVersion).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(response, "Date" as CFString, currentHTTPDateCFString())
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "text/plain; charset=utf-8" as CFString)
        let bodyString = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n"
        let bodyData = bodyString.data(using: .utf8)!
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Length" as CFString, String(bodyData.count) as CFString)
        if withBody {
            CFHTTPMessageSetBody(response, bodyData as CFData)
        }
        let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
        try? fileHandle.writeData(data)
        completion()
    }

    private func respondWithMethodNotAllowed(fileHandle: FileHandle, allowedMethods: [String], withBody: Bool, completion: @escaping () -> Void) {
        let statusCode = 405
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, nil, server.httpVersion).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(response, "Date" as CFString, currentHTTPDateCFString())
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "text/plain; charset=utf-8" as CFString)
        CFHTTPMessageSetHeaderFieldValue(response, "Allow" as CFString, allowedMethods.joined(separator: ", ") as CFString)
        let bodyString = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n"
        let bodyData = bodyString.data(using: .utf8)!
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Length" as CFString, String(bodyData.count) as CFString)
        if withBody {
            CFHTTPMessageSetBody(response, bodyData as CFData)
        }
        let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
        try? fileHandle.writeData(data)
        completion()
    }

    private func respondToRequestForEventSource(_ request: CFHTTPMessage, fileHandle: FileHandle, withBody: Bool, completion: @escaping () -> Void) {
        let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, nil, server.httpVersion).takeRetainedValue()
        CFHTTPMessageSetHeaderFieldValue(response, "Date" as CFString, currentHTTPDateCFString())
        CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "text/event-stream" as CFString)
        CFHTTPMessageSetHeaderFieldValue(response, "Transfer-Encoding" as CFString, "chunked" as CFString)
        if withBody {
            CFHTTPMessageSetBody(response, CFDataCreate(kCFAllocatorDefault, "", 0))
        }
        let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
        try? fileHandle.writeData(data)
        if withBody {
            eventStreamQueueMap.enqueue(chunk: chunkForCurrentState(), forKey: fileHandle)
            let thread = Thread(target: self, selector: #selector(runInSubthread), object: (fileHandle, completion))
            thread.name = "com.github.manicmaniac.ApolloDeveloperKit.private"
            thread.start()
        }
    }

    @objc private func runInSubthread(_ argument: Any) {
        let (fileHandle, completion) = argument as! (FileHandle, () -> Void)
        while let chunk = eventStreamQueueMap.dequeue(key: fileHandle) {
            do {
                try fileHandle.writeData(chunk.data)
            } catch {
                return completion()
            }
        }
        let chunk = EventStreamChunk()
        try? fileHandle.writeData(chunk.data)
        completion()
    }

    private func respondToRequestForDocumentRoot(url: URL, request: CFHTTPMessage, fileHandle: FileHandle, withBody: Bool, completion: @escaping () -> Void) {
        var documentURL = Bundle(for: type(of: self)).url(forResource: "Assets", withExtension: nil)!
        documentURL.appendPathComponent(url.path)
        do {
            var resourceValues = try documentURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
            if resourceValues.isDirectory! {
                documentURL.appendPathComponent("index.html")
                resourceValues = try documentURL.resourceValues(forKeys: [.fileSizeKey])

            }
            let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, nil, server.httpVersion).takeRetainedValue()
            CFHTTPMessageSetHeaderFieldValue(response, "Date" as CFString, currentHTTPDateCFString())
            CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, mimeType(for: documentURL.pathExtension) as CFString)
            CFHTTPMessageSetHeaderFieldValue(response, "Content-Length" as CFString, String(resourceValues.fileSize!) as CFString)
            if withBody {
                let bodyData = try Data(contentsOf: documentURL)
                CFHTTPMessageSetBody(response, bodyData as CFData)
            }
            let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
            try? fileHandle.writeData(data)
            completion()
        } catch CocoaError.fileReadNoSuchFile {
            respondWithNotFound(fileHandle: fileHandle, withBody: withBody, completion: completion)
        } catch let error {
            print(error)
            respondWithInternalServerError(fileHandle: fileHandle, withBody: withBody, completion: completion)
        }
    }

    private func respondToRequestForGraphQLRequest(_ request: CFHTTPMessage, fileHandle: FileHandle, completion: @escaping () -> Void) {
        guard CFHTTPMessageCopyHeaderFieldValue(request, "Content-Length" as CFString) != nil else {
            return respondWithLengthRequired(fileHandle: fileHandle, completion: completion)
        }
        guard let body = CFHTTPMessageCopyBody(request)?.takeRetainedValue() as Data? else {
            return respondWithBadRequest(fileHandle: fileHandle, withBody: true, completion: completion)
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
                    let response = CFHTTPMessageCreateResponse(kCFAllocatorDefault, 200, nil, self.server.httpVersion).takeRetainedValue()
                    CFHTTPMessageSetHeaderFieldValue(response, "Date" as CFString, self.currentHTTPDateCFString())
                    CFHTTPMessageSetHeaderFieldValue(response, "Content-Type" as CFString, "application/json" as CFString)
                    CFHTTPMessageSetHeaderFieldValue(response, "Content-Length" as CFString, String(body.count) as CFString)
                    CFHTTPMessageSetBody(response, body as CFData)
                    let data = CFHTTPMessageCopySerializedMessage(response)!.takeRetainedValue() as Data
                    try? fileHandle.writeData(data)
                    completion()
                } catch let error {
                    self.respondWithBadRequest(fileHandle: fileHandle, jsError: JSError(error: error), completion: completion)
                }
            }
        } catch let error {
            respondWithBadRequest(fileHandle: fileHandle, jsError: JSError(error: error), completion: completion)
        }
    }

    private func mimeType(for pathExtension: String) -> String {
        switch pathExtension {
        case "html":
            return "text/html; charset=utf-8"
        case "js":
            return "application/javascript"
        case "css":
            return "text/css"
        default:
            return "application/octet-stream"
        }
    }

    private func currentHTTPDateCFString() -> CFString {
        return CFDateFormatterCreateStringWithAbsoluteTime(kCFAllocatorDefault, dateFormatter, CFAbsoluteTimeGetCurrent())
    }
}

// MARK: - DebuggableNormalizedCacheDelegate

extension ApolloDebugServer: DebuggableNormalizedCacheDelegate {
    func normalizedCache(_ normalizedCache: DebuggableNormalizedCache, didChangeRecords records: RecordSet) {
        eventStreamQueueMap.enqueueForAllKeys(chunk: chunkForCurrentState())
    }
}

// MARK: - DebuggableNetworkTransportDelegate

extension ApolloDebugServer: DebuggableNetworkTransportDelegate {
    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, willSendOperation operation: Operation) where Operation: GraphQLOperation {
        if !(operation is GraphQLRequest) {
            queryManager.networkTransport(networkTransport, willSendOperation: operation)
            eventStreamQueueMap.enqueueForAllKeys(chunk: chunkForCurrentState())
        }
    }

    func networkTransport<Operation>(_ networkTransport: DebuggableNetworkTransport, didSendOperation operation: Operation, response: GraphQLResponse<Operation>?, error: Error?) where Operation: GraphQLOperation {
        if !(operation is GraphQLRequest) {
            queryManager.networkTransport(networkTransport, didSendOperation: operation, response: response, error: error)
            eventStreamQueueMap.enqueueForAllKeys(chunk: chunkForCurrentState())
        }
    }
}
