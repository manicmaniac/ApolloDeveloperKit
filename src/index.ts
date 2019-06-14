import ApolloClientProxy from "./ApolloClientProxy";

declare global {
  interface Window { __APOLLO_CLIENT__: ApolloClientProxy }
}

const apolloClient = new ApolloClientProxy();
apolloClient.startListening();
window.__APOLLO_CLIENT__ = apolloClient;
