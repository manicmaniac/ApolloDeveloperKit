//
//  HTTPRequest+AnyGraphQLOperation.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/3/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
@testable import ApolloDeveloperKit

extension HTTPRequest where Operation == AnyGraphQLOperation {
    convenience init<Operation>(_ httpRequest: HTTPRequest<Operation>) where Operation: GraphQLOperation {
        self.init(graphQLEndpoint: httpRequest.graphQLEndpoint,
                  operation: AnyGraphQLOperation(httpRequest.operation),
                  contentType: httpRequest.additionalHeaders["Content-Type"]!,
                  clientName: httpRequest.additionalHeaders["apollographql-client-name"]!,
                  clientVersion: httpRequest.additionalHeaders["apollographql-client-version"]!,
                  additionalHeaders: httpRequest.additionalHeaders)
    }
}
