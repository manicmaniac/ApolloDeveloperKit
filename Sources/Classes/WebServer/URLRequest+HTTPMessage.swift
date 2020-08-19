//
//  URLRequest+HTTPMessage.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/27/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

extension URLRequest {
    init(httpMessage: HTTPRequestMessage) {
        self.init(url: httpMessage.requestURL!)
        self.httpMethod = httpMessage.requestMethod
        self.allHTTPHeaderFields = httpMessage.allHeaderFields
        self.httpBody = httpMessage.body
    }
}
