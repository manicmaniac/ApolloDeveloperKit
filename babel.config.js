// Since apollo-client-devtools uses babel internally, this config file is necessary to run integration tests.
// ApolloDeveloperKit uses tsc command itself to compile .ts files so it doesn't need babel except for testing.
module.exports = {
  presets: ["@babel/preset-env"]
};
