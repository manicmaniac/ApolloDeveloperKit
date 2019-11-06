import {} from 'apollo-client-devtools';
import ApolloClientPretender from "./ApolloClientPretender";

const apolloClient = new ApolloClientPretender();
window.__APOLLO_CLIENT__ = apolloClient;
