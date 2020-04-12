Example
=======

macOS and iOS example apps for `ApolloDeveloperKit`.

Prerequisites
-------------

- Xcode (`>= 10.1`)
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

Currently `API.swift` is generated with Node.js `apollo@2.16.3` package.

To update schema, run the following command.
You may want to change the version of `apollo` like `npx apollo@2.15.0 codegen:generate ...`.

```
npx apollo@2.16.3 codegen:generate --includes=Example/*.graphql --target=swift --localSchemaFile=Example/schema.json Example/API.swift
```
