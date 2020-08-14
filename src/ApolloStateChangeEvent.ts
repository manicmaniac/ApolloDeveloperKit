import { DocumentNode } from 'apollo-link'

type ApolloStateChangeEvent = {
  state: {
    queries: {
      string: {
        document: DocumentNode,
        variables?: object,
        previousVariables?: object,
        networkError?: object,
        graphQLErrors?: [object]
      }
    },
    mutations: {
      string: {
        mutation: DocumentNode,
        variables?: object,
        loading: boolean,
        error?: object
      }
    }
  },
  dataWithOptimisticResults: object
}

export default ApolloStateChangeEvent
