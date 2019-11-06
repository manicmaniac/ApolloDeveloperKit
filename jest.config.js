module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'jsdom',
  transformIgnorePatterns: [
    "node_modules/(?!(apollo-client-devtools)/)"
  ],
  transform: {
    "^.+\\.js$": ["babel-jest"]
  }
};
