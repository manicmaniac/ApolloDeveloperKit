//
//  MIMEType.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 9/29/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import CoreFoundation

/**
 * `MIMEType` represents a very limited part of MIME types.
 *
 * - SeeAlso: https://www.iana.org/assignments/media-types/media-types.xhtml
 */
enum MIMEType {
    case html(String.Encoding?)
    case javascript
    case json
    case css
    case plainText(String.Encoding?)
    case png
    case eventStream // https://html.spec.whatwg.org/multipage/iana.html#text/event-stream
    case octetStream

    init(pathExtension: String, encoding: String.Encoding?) {
        switch pathExtension {
        case "html":
            self = .html(encoding)
        case "js":
            self = .javascript
        case "json":
            self = .json
        case "css":
            self = .css
        case "txt":
            self = .plainText(encoding)
        case "png":
            self = .png
        default:
            self = .octetStream
        }
    }
}

// MARK: CustomStringConvertible

extension MIMEType: CustomStringConvertible {
    var description: String {
        switch self {
        case .html(let encoding?):
            return "text/html; charset=\(encoding.ianaCharSetName)"
        case .html(nil):
            return "text/html"
        case .javascript:
            return "application/javascript"
        case .json:
            return "application/json"
        case .css:
            return "text/css"
        case .plainText(let encoding?):
            return "text/plain; charset=\(encoding.ianaCharSetName)"
        case .plainText(nil):
            return "text/plain"
        case .png:
            return "image/png"
        case .eventStream:
            return "text/event-stream"
        case .octetStream:
            return "application/octet-stream"
        }
    }
}

private extension String.Encoding {
    var ianaCharSetName: String {
        let cfStringEncoding = CFStringConvertNSStringEncodingToEncoding(rawValue)
        return CFStringConvertEncodingToIANACharSetName(cfStringEncoding) as String
    }
}
