//
//  AnyGraphQLSelectionSet.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/24/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

/**
 * A type erasure class for `GraphQLSelectionSet`.
 */
struct AnyGraphQLSelectionSet: GraphQLSelectionSet {
    static let selections = [GraphQLSelection]()

    let resultMap: ResultMap

    init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
    }
}
