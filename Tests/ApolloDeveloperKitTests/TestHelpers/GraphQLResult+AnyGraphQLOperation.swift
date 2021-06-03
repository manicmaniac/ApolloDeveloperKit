//
//  GraphQLResult+AnyGraphQLOperation.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 6/3/21.
//  Copyright © 2021 Ryosuke Ito. All rights reserved.
//

import Apollo
@testable import ApolloDeveloperKit

extension GraphQLResult where Data == AnyGraphQLOperation.Data {
    init<Data>(_ graphQLResult: GraphQLResult<Data>) where Data: GraphQLSelectionSet {
        self.init(data: try? graphQLResult.data.flatMap(AnyGraphQLOperation.Data.init(_:)),
                  extensions: graphQLResult.extensions,
                  errors: graphQLResult.errors,
                  source: convert(source: graphQLResult.source),
                  dependentKeys: nil)
    }
}

private func convert<Data>(source: GraphQLResult<Data>.Source) -> GraphQLResult<AnyGraphQLOperation.Data>.Source where Data: GraphQLSelectionSet {
    switch source {
    case .cache:
        return .cache
    case .server:
        return .server
    }
}
