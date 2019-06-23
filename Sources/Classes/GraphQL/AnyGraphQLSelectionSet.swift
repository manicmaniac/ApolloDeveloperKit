//
//  AnyGraphQLSelectionSet.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 6/24/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

public class AnyGraphQLSelectionSet: GraphQLSelectionSet {
    public static var selections = [GraphQLSelection]()

    public var resultMap: ResultMap

    public required init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
    }
}
