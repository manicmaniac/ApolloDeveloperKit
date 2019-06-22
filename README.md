ApolloDeveloperKit
==================

[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ApolloDeveloperKit.svg)](https://img.shields.io/cocoapods/v/ApolloDeveloperKit.svg)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/ApolloDeveloperKit.svg?style=flat)](https://alamofire.github.io/ApolloDeveloperKit)

[Apollo Client Devtools](https://github.com/apollographql/apollo-client-devtools) bridge for [Apollo iOS](https://github.com/apollographql/apollo-ios).

**Warning: Currently this program is at the early stage. See [Known Bugs](#known-bugs).**

Screenshots
-----------

<img width="960" alt="apollo-developer-kit-queries-1920" src="https://user-images.githubusercontent.com/1672393/59568132-81a20180-90b1-11e9-9207-b2070b26e790.png">

Prerequisites
-------------

- Xcode 10
- Carthage
- Google Chrome
- [Apollo Client Devtools](https://github.com/apollographql/apollo-client-devtools)

Installation
------------

### Install from Carthage

Add the following lines to your Cartfile.

```
github "apollographql/apollo-ios"
github "manicmaniac/ApolloDeveloperKit"
```

Then run `carthage update --platform iOS`.

### Install from CocoaPods

Add the following lines to your Podfile.

```
pod 'Apollo'
pod 'ApolloDeveloperKit'
```

Then run `pod install`.

Setup
-----

First, in order to hook Apollo's cache and network layer, you need to use `DebuggableNetworkTransport` and `DebuggableInMemoryNormalizedCache` instead of usual ones.

```swift
let networkTransport = DebuggableNetworkTransport(networkTransport: HTTPNetworkTransport(url: url))
let cache = DebuggableInMemoryNormalizedCache()
```

Second, instantiate `ApolloStore` and `ApolloClient` with debuggable ingredients.

```swift
let store = ApolloStore(cache: cache)
let client = ApolloClient(networkTransport: networkTransport: store: store)
```

Finally, create `ApolloDebugServer` and run.

```swift
let debugServer = ApolloDebugServer(cache: cache, networkTransport: networkTransport)
self.debugServer = debugServer // Note: you need to retain debugServer's reference
debugServer.start(port: 8080)
```

Full example:

```swift
import Apollo
import ApolloDeveloperKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var client: ApolloClient!
    private var debugServer: ApolloDebugServer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let url = URL(string: "https://example.com/graphql")!
        #if DEBUG
            let networkTransport = DebuggableNetworkTransport(networkTransport: HTTPNetworkTransport(url: url))
            let cache = DebuggableInMemoryNormalizedCache()
            let store = ApolloStore(cache: cache)
            client = ApolloClient(networkTransport: networkTransport, store: store)
            debugServer = ApolloDebugServer(cache: cache, networkTransport: networkTransport)
            debugServer.start(port: 8080)
        #else
            client = ApolloClient(url: url)
        #endif
        return true
    }
}
```

Usage
-----

Open browser after launching Simulator and jump to `http://localhost:8080` (or other specified port) on your Chrome.
Then [open developer tools](https://developers.google.com/web/tools/chrome-devtools/open) and select `Apollo` tab.

Development
-----------

### Run Example App

Since Example app uses [Github GraphQL API](https://developer.github.com/v4/), you have to set your Github API token to Xcode Project.

1. Get Github API token from [here](https://github.com/settings/tokens).
2. Open Example/Info.plist and set your token as `GithubAPIToken`.
3. Open Xcode and run ApolloDeveloperKitExample app.

Known Bugs
----------

### GraphiQL tab doesn't work

It's not been implemented yet.

### Other bugs and glitches

Don't hesitate to report me from issues.

License
-------

This software is distributed under the MIT license.
See LICENSE for more detail.
