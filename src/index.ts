import {} from 'apollo-client-devtools'
import ApolloClientPretender from "./ApolloClientPretender"

window.__APOLLO_CLIENT__ = new ApolloClientPretender()
