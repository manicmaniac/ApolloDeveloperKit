import ApolloClientPretender from "./ApolloClientPretender";

declare global {
  interface Window { __APOLLO_CLIENT__: ApolloClientPretender }
}

const apolloClient = new ApolloClientPretender();
window.__APOLLO_CLIENT__ = apolloClient;
