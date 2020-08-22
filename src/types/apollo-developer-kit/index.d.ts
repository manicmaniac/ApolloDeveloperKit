export interface Schema {
    /**
     * GraphQL operation request passed from client to server.
     */
    operation?: Operation;
    /**
     * State change event pushed from server to client.
     */
    stateChange?: StateChange;
}

/**
 * GraphQL operation request passed from client to server.
 */
export interface Operation {
    operationIdentifier?: string;
    operationName?:       string;
    query:                string;
    variables?:           { [key: string]: any };
}

/**
 * State change event pushed from server to client.
 */
export interface StateChange {
    dataWithOptimisticResults: { [key: string]: any };
    state:                     State;
}

export interface State {
    mutations: Mutation[];
    queries:   Query[];
}

export interface Mutation {
    error?:     ErrorLike;
    loading:    boolean;
    mutation:   string;
    variables?: { [key: string]: any };
}

/**
 * JavaScript error serialized to JSON.
 */
export interface ErrorLike {
    columnNumber?: number;
    fileName?:     string;
    lineNumber?:   number;
    message:       string;
    name:          string;
}

export interface Query {
    document:           string;
    graphQLErrors?:     ErrorLike[];
    networkError?:      ErrorLike;
    previousVariables?: { [key: string]: any };
    variables?:         { [key: string]: any };
}
