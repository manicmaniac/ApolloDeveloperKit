//
//  HTTPResponse+AnyGraphQLOperation.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/3/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
@testable import ApolloDeveloperKit

extension HTTPResponse where Operation == AnyGraphQLOperation {
    convenience init<Operation>(_ httpResponse: HTTPResponse<Operation>) where Operation: GraphQLOperation {
        self.init(response: httpResponse.httpResponse,
                  rawData: httpResponse.rawData,
                  parsedResponse: httpResponse.parsedResponse.flatMap(GraphQLResult.init(_:)))
    }
}
