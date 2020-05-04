Example
=======

macOS and iOS example apps for `ApolloDeveloperKit`.

Prerequisites
-------------

- Xcode (`>= 11.2.1`)
- Carthage

Installation
------------

1. Install dependency via Carthage
    - You may want to modify `Cartfile.resolved` to use the preferred version of `Apollo` beforehand.
    - Run `carthage bootstrap --platform iOS` or `carthage bootstrap --platform macOS`
2. Open the root `ApolloDeveloperKit.xcodeproj`.
3. Ensure Xcode scheme to be set to `ApolloDeveloperKitExample-macOS` or `ApolloDeveloperKitExample-iOS`.
4. Run build

Notes
-----

### Updating Schema

To update schema, run the following command.

```
../Carthage/Checkouts/apollo-ios/scripts/run-bundled-codegen.sh schema:download --endpoint=http://localhost:8080/graphql
../Carthage/Checkouts/apollo-ios/scripts/run-bundled-codegen.sh codegen:generate --includes=*.graphql --target=swift --localSchemaFile=schema.json API.swift
```
