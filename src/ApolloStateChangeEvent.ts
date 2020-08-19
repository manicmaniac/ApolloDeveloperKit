import { DocumentNode } from 'apollo-link'

type Variables = {
  [key: string]: any
}

type CacheStorage = {
  [key: string]: Record
}

type Record = {
  key: string
  fields: {
    [key: string]: any
  }
}

type Query = {
  document: string | DocumentNode,
  variables?: Variables,
  previousVariables?: Variables,
  networkError?: Error,
  graphQLErrors?: [Error]
}

type Mutation = {
  mutation: string | DocumentNode,
  variables?: Variables,
  loading: boolean,
  error?: Error
}

type ApolloStateChangeEvent = {
  state: {
    queries: {[key: string]: Query},
    mutations: {[key: string]: Mutation}
  },
  dataWithOptimisticResults: CacheStorage
}

export default ApolloStateChangeEvent
