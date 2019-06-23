import ApolloClientProxy from "./ApolloClientProxy";

declare global {
  interface Window { __APOLLO_CLIENT__: ApolloClientProxy }
}

const apolloClient = new ApolloClientProxy();
window.__APOLLO_CLIENT__ = apolloClient;
