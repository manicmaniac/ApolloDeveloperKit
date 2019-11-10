//
//  ContentTypeSniffer.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 11/10/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation
import MobileCoreServices

final class ContentTypeSniffer {
    static let shared = ContentTypeSniffer()

    private let cache = NSCache<NSString, NSString>()
    private let lock = NSLock()

    func contentType(for pathExtension: String, preferredEncoding: String.Encoding) -> String {
        lock.lock()
        defer { lock.unlock() }
        if let contentType = cache.object(forKey: pathExtension as NSString) {
            return contentType as String
        }
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as CFString, nil)?.takeRetainedValue(),
            !UTTypeIsDynamic(uti),
            let mediaType = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() as String? else {
                return "application/octet-stream"
        }
        guard UTTypeConformsTo(uti, kUTTypeText) else {
            return mediaType
        }
        let cfStringEncoding = CFStringConvertNSStringEncodingToEncoding(preferredEncoding.rawValue)
        let ianaCharSetName = CFStringConvertEncodingToIANACharSetName(cfStringEncoding)!
        let contentType = "\(mediaType); charset=\(ianaCharSetName)"
        cache.setObject(contentType as NSString, forKey: pathExtension as NSString)
        return contentType
    }
}
