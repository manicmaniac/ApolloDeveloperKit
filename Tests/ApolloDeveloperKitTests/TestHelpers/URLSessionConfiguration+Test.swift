//
//  URLSessionConfiguration+Test.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 11/10/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Foundation

extension URLSessionConfiguration {
    static var test: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpMaximumConnectionsPerHost = 256
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 2
        return configuration
    }
}
