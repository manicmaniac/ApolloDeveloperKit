//
//  HTTPNetworkTransport+Compatibility.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 9/28/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

extension HTTPNetworkTransport {
    convenience init(url: URL, configuration: URLSessionConfiguration = .default, sendOperationIdentifiers: Bool = false, useGETForQueries: Bool = false, delegate: HTTPNetworkTransportDelegate? = nil) {
        let session = URLSession(configuration: configuration)
        self.init(url: url, session: session, sendOperationIdentifiers: sendOperationIdentifiers, useGETForQueries: useGETForQueries, delegate: delegate)
    }
}
