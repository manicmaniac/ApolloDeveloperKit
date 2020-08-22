// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let schema = try Schema(json)

import Foundation

// MARK: - Schema
struct Schema {
    /// GraphQL operation request passed from client to server.
    let operation: Operation?
    /// State change event pushed from server to client.
    let stateChange: StateChange?
}

/// GraphQL operation request passed from client to server.
// MARK: - Operation
struct Operation {
    let operationIdentifier, operationName: String?
    let query: String
    let variables: [String: Any?]?
}

/// State change event pushed from server to client.
// MARK: - StateChange
struct StateChange {
    let dataWithOptimisticResults: [String: Any?]
    let state: State
}

// MARK: - State
struct State {
    let mutations: [Mutation]
    let queries: [Query]
}

// MARK: - Mutation
struct Mutation {
    let error: ErrorLike?
    let loading: Bool
    let mutation: String
    let variables: [String: Any?]?
}

/// JavaScript error serialized to JSON.
// MARK: - ErrorLike
struct ErrorLike {
    let columnNumber: Int?
    let fileName: String?
    let lineNumber: Int?
    let message, name: String
}

// MARK: - Query
struct Query {
    let document: String
    let graphQLErrors: [ErrorLike]?
    let networkError: ErrorLike?
    let previousVariables, variables: [String: Any?]?
}
