//
//  HTTPRequestContext.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 9/14/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

final class HTTPRequestContext {
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
        return dateFormatter
    }()

    private let request: HTTPRequestMessage
    private let connection: HTTPConnection
    private var responseHeaderFields = [String: String]()

    init(request: HTTPRequestMessage, connection: HTTPConnection) {
        assert(request.isHeaderComplete)
        self.request = request
        self.connection = connection
    }

    var version: String {
        return request.version
    }

    var requestURL: URL {
        return request.requestURL!
    }

    var requestMethod: String {
        return request.requestMethod!
    }

    var requestBody: Data? {
        return request.body
    }

    func value(forRequest headerField: String) -> String? {
        return request.value(for: headerField)
    }

    func setContentLength(_ contentLength: Int) {
        setValue(String(contentLength), forResponse: "Content-Length")
    }

    func setContentType(_ contentType: MIMEType) {
        setValue(String(describing: contentType), forResponse: "Content-Type")
    }

    func respond(statusCode: Int) -> HTTPOutputStream {
        let message = HTTPResponseMessage(statusCode: statusCode, statusDescription: nil, httpVersion: version)
        for (headerField, value) in responseHeaderFields {
            message.setValue(value, for: headerField)
        }
        message.setValue(HTTPRequestContext.dateFormatter.string(from: Date()), for: "Date")
        message.setBody(Data())
        connection.write(data: message.serialize()!)
        return connection
    }

    func respond(proxying response: HTTPURLResponse) -> HTTPOutputStream {
        for case (let headerField as String, let value as String) in response.allHeaderFields {
            setValue(value, forResponse: headerField)
        }
        return respond(statusCode: response.statusCode)
    }

    func setValue(_ value: String, forResponse headerField: String) {
        responseHeaderFields[headerField] = value
    }
}
