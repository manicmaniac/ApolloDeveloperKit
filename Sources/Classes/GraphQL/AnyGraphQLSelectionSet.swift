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
class AnyGraphQLSelectionSet: GraphQLSelectionSet {
    static var selections = [GraphQLSelection]()

    var resultMap: ResultMap

    required init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
    }
}
