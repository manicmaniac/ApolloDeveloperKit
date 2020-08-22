//
//  Schema+JSONEncodable.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/22/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Apollo

extension StateChange: JSONEncodable {
    var jsonValue: JSONValue {
        return [
            "dataWithOptimisticResults": dataWithOptimisticResults.jsonValue,
            "state": state.jsonValue
        ]
    }
}

extension State: JSONEncodable {
    var jsonValue: JSONValue {
        return [
            "mutations": mutations.jsonValue,
            "queries": queries.jsonValue
        ]
    }
}

extension Mutation: JSONEncodable {
    var jsonValue: JSONValue {
        return [
            "error": error.jsonValue,
            "loading": loading.jsonValue,
            "mutation": mutation.jsonValue,
            "variables": variables.jsonValue
        ]
    }
}

extension ErrorLike: JSONEncodable {
    var jsonValue: JSONValue {
        return [
            "columnNumber": columnNumber.jsonValue,
            "fileName": fileName.jsonValue,
            "lineNumber": lineNumber.jsonValue,
            "message": message.jsonValue,
            "name": name.jsonValue
        ]
    }
}

extension Query: JSONEncodable {
    var jsonValue: JSONValue {
        return [
            "document": document.jsonValue,
            "graphQLErrors": graphQLErrors.jsonValue,
            "networkError": networkError.jsonValue,
            "previousVariables": previousVariables.jsonValue,
            "variables": variables.jsonValue
        ]
    }
}
