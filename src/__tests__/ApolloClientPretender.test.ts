import ApolloClientPretender from '../ApolloClientPretender';

describe('ApolloClientPretender', () => {
  describe('#version', () => {
    it('should be 2.0.0', () => {
      const apolloClient = new ApolloClientPretender();
      expect(apolloClient.version).toBe('2.0.0');
    });
  });
});
