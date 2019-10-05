//
//  HTTPResponse.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 9/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

/**
 * A Swifty wrapper for CFHTTPMessage instantiated as a response.
 */
public class HTTPResponse {
    private let message: CFHTTPMessage

    private static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
        return dateFormatter
    }()

    required init(statusCode: Int, httpVersion: CFString) {
        message = CFHTTPMessageCreateResponse(kCFAllocatorDefault, statusCode, nil, httpVersion).takeRetainedValue()
    }

    convenience init(httpURLResponse: HTTPURLResponse, body: Data?, httpVersion: CFString) {
        self.init(statusCode: httpURLResponse.statusCode, httpVersion: httpVersion)
        for case let (field as String, value as String) in httpURLResponse.allHeaderFields {
            setValue(value, forHTTPHeaderField: field)
        }
        if let body = body {
            setBody(body)
        }
    }

    class func errorResponse(for statusCode: Int, httpVersion: CFString, withDefaultBody: Bool) -> HTTPResponse {
        precondition(statusCode >= 300)
        let response = self.init(statusCode: statusCode, httpVersion: httpVersion)
        response.setDateHeaderField()
        response.setContentTypeHeaderField(.plainText(.utf8))
        let body = "\(statusCode) \(HTTPURLResponse.localizedString(forStatusCode: statusCode))\n".data(using: .utf8)!
        response.setContentLengthHeaderField(withDefaultBody ? body.count : 0)
        if withDefaultBody {
            response.setBody(body)
        }
        return response
    }

    class func errorResponse(for statusCode: Int, httpVersion: CFString, body: Data) -> HTTPResponse {
        precondition(statusCode >= 300)
        let response = self.init(statusCode: statusCode, httpVersion: httpVersion)
        response.setDateHeaderField()
        response.setContentTypeHeaderField(.plainText(.utf8))
        response.setContentLengthHeaderField(body.count)
        response.setBody(body)
        return response
    }

    func setValue(_ value: String?, forHTTPHeaderField field: String) {
        CFHTTPMessageSetHeaderFieldValue(message, field as CFString, value as CFString?)
    }

    func setDateHeaderField(_ date: Date = Date()) {
        setValue(HTTPResponse.dateFormatter.string(from: date), forHTTPHeaderField: "Date")
    }

    func setContentTypeHeaderField(_ contentType: MimeType) {
        setValue(String(describing: contentType), forHTTPHeaderField: "Content-Type")
    }

    func setContentLengthHeaderField(_ contentLength: Int) {
        setValue(String(contentLength), forHTTPHeaderField: "Content-Length")
    }

    func setBody(_ body: Data) {
        CFHTTPMessageSetBody(message, body as CFData)
    }

    func serialize() -> Data? {
        return CFHTTPMessageCopySerializedMessage(message)?.takeUnretainedValue() as Data?
    }
}
