ApolloDeveloperKit
==================

[![Build Status](https://travis-ci.org/manicmaniac/ApolloDeveloperKit.svg?branch=master)](https://travis-ci.org/manicmaniac/ApolloDeveloperKit)
[![Maintainability](https://api.codeclimate.com/v1/badges/c45fc7657ce194edee35/maintainability)](https://codeclimate.com/github/manicmaniac/ApolloDeveloperKit/maintainability)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ApolloDeveloperKit.svg)](https://cocoapods.org/pods/ApolloDeveloperKit)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Platform](https://img.shields.io/cocoapods/p/ApolloDeveloperKit.svg?style=flat)](https://manicmaniac.github.io/ApolloDeveloperKit/)

[Apollo Client Devtools](https://github.com/apollographql/apollo-client-devtools) bridge for [Apollo iOS](https://github.com/apollographql/apollo-ios).

Overview
--------

ApolloDeveloperKit is an iOS / macOS library which works as a bridge between Apollo iOS client and [Apollo Client Developer tools](https://chrome.google.com/webstore/detail/apollo-client-developer-t/jdkknkkbebbapilgoeccciglkfbmbnfm).

This library adds an ability to watch the sent queries or mutations simultaneously, and also has the feature to request arbitrary operations from embedded GraphiQL console.

Screenshots
-----------

<img width="1332" alt="apollo-developer-kit-animation" src="https://user-images.githubusercontent.com/1672393/62706435-0db01580-b9df-11e9-9033-cb8055074b91.gif">

Prerequisites
-------------

- Xcode `>= 10.1`
- Google Chrome
- [Apollo iOS](https://github.com/apollographql/apollo-ios) `>= 0.9.1`, `< 0.20.0`
- [Apollo Client Devtools](https://github.com/apollographql/apollo-client-devtools)

Installation
------------

### Install from CocoaPods

Add the following lines to your Podfile.

```ruby
pod 'Apollo'
pod 'ApolloDeveloperKit', '~> 0.7.0'
```

Then run `pod install`.

### Install from Carthage

Add the following lines to your Cartfile.

```
github "apollographql/apollo-ios"
github "manicmaniac/ApolloDeveloperKit"
```

Then run `carthage update --platform iOS` or `carthage update --platform Mac`.

#### For Xcode 10.1 (Swift 4.2)

If you are using Xcode 10.1, where Swift 5 is not available, the install step could be a bit tricky though Cartfile can be as it is.
Contrary to CocoaPods, Carthage doesn't select the compiler by itself so the only way to force it to use Swift 4.2 is to inject a Xcode configuration file.

```bash
echo APOLLO_DEVELOPER_KIT_SWIFT_VERSION=4.2 >ApolloDeveloperKit.xcconfig
XCODE_XCCONFIG_FILE="$PWD/ApolloDeveloperKit.xcconfig" carthage update --platform iOS
rm ApolloDeveloperKit.xcconfig
```

Note `XCODE_XCCONFIG_FILE` should be an absolute path somehow.

Not recommended but as plan B, you can use `ApolloDeveloperKit ~> 0.3.3` which only supports Swift 4.2 as well.

### Install from Swift Package Manager (>= Xcode 11)

Currently support for Swift Package Manager is at the very first step.
I recommend to install `ApolloDeveloperKit` in other ways above.

1. Open your Xcode then select the menu item `File` - `Swift Packages` - `Add Package Dependency...`.
2. Enter the URL of this repository (https://github.com/manicmaniac/ApolloDeveloperKit) and click `Next`.
3. Select the version `0.7.0` or higher.

#### Limitations

The unit test bundle `ApolloDeveloperKitTests` cannot be built with `swift test` command.
It is because that Swift Package Manager doesn't support running script before building but `ApolloDeveloperKitTests` needs a run script phase to preprocess Swift source files.

However usually application developers don't need to test libraries so don't too worry about it.

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
debugServer.start(port: 8081)
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
            let cache = DebuggableNormalizedCache(cache: InMemoryNormalizedCache())
            let store = ApolloStore(cache: cache)
            client = ApolloClient(networkTransport: networkTransport, store: store)
            debugServer = ApolloDebugServer(networkTransport: networkTransport, cache: cache)
            do {
                try debugServer.start(port: 8081)
            } catch let error {
                print(error)
            }
        #else
            client = ApolloClient(url: url)
        #endif
        return true
    }
}
```

Usage
-----

**If you don't have [Google Chrome](https://www.google.com/chrome) and [Apollo Client Developer Tools](https://chrome.google.com/webstore/detail/apollo-client-developer-t/jdkknkkbebbapilgoeccciglkfbmbnfm), install them before proceeding the following steps.**

1. Launch your app on your device or simulator.
2. Open Google Chrome and jump to the server's URL (in case your app runs the above example on a simulator, the URL would be `http://localhost:8081`).
    - You will see `ApolloDebugServer is running!` on your browser's tab.
    - If not, make sure the server runs and the specified URL is correct.
    - On a real device, the host would be other than `localhost` but you can check what it is with `ApolloDebugServer.serverURL`.
3. Open [Google Chrome DevTools](https://developers.google.com/web/tools/chrome-devtools/open).
4. Select `Apollo` tab.
    - You will see tabs like `GraphiQL`, `Queries`, `Mutations` on the left pane.
    - If not, reload the tab and wait until it's connected again.

Excluding ApolloDeveloperKit from Release (App Store) Builds
------------------------------------------------------------

All instructions in this section are written based on [Flipboard/FLEX](https://github.com/Flipboard/FLEX)'s way.

Since ApolloDeveloperKit is originally designed for debug use only, it should not be exposed to end-users.

Fortunately, it is easy to exclude ApolloDeveloperKit framework from Release builds. The strategies differ depending on how you integrated it in your project, and are described below.

Please make sure your code is properly excluding ApolloDeveloperKit with `#if DEBUG` statements before starting these instructions.
Otherwise it will be linked to your app unexpectedly.
See `Example/AppDelegate.swift` to see how to do it.

### For CocoaPods users

CocoaPods automatically excludes ApolloDeveloperKit from release builds if you only specify the Debug configuration for CocoaPods in your Podfile.

### For Carthage users

1. Do NOT add `ApolloDeveloperKit.framework` to the embedded binaries of your target, as it would otherwise be included in all builds (therefore also in release ones).
2. Instead, add `$(PROJECT_DIR)/Carthage/Build/iOS` or `$(PROJECT_DIR)/Carthage/Build/Mac` to your target *Framework Search Paths* (this setting might already be present if you already included other frameworks with Carthage).
This makes it possible to import the ApolloDeveloperKit framework from your source files. It does not harm if this setting is added for all configurations, but it should at least be added for the debug one.
3. Add a *Run Script Phase* to your target (inserting it alter the existing `Link Binary with Libraries` phase, for example), and which will embed `ApolloDeveloperKit.framework` in debug builds only:

```bash
if [ "$CONFIGURATION" = Debug ]; then
  /usr/local/bin/carthage copy-frameworks
fi
```

Finally, add `$(SRCROOT)/Carthage/Build/iOS/ApolloDeveloperKit.framework` or `$(SRCROOT)/Carthage/Build/Mac/ApolloDeveloperKit.framework` as input file of this script phase.

### For users those who copy all the source files to the project manually

Now there's no easy way but you can exclude ApolloDeveloperKit by setting user defined build variable named `EXCLUDED_SOURCE_FILE_NAMES`.
The value for the variable is a space-separated list of each filenames in ApolloDeveloperKit.
Sorry for the inconvenience.

Console Redirection
-------------------

`ApolloDeveloperKit` supports console redirection.
When it is enabled, all logs written in stdout (usually written with `print()`) and stderr (written with `NSLog()`) are redirected to the web browser's console as well.

This feature is disabled by default so you may want to enable it explicitly.

```swift
debugServer = ApolloDebugServer(networkTransport: networkTransport, cache: cache)
debugServer.enableConsoleRedirection = true
```

Then open the console in Google Chrome Devtools.
You will see logs in your iPhone or simulator.

In the browser console, logs written in stdout are colored in [blue-green](https://www.color-hex.com/color/5f9ea0) and stderr are [orange](https://www.color-hex.com/color/ff6347) so that you can distinguish them from ordinary browser logs.

<img width="1440" alt="console-redirection.png" src="https://user-images.githubusercontent.com/1672393/68502106-07ae2700-02a3-11ea-8d35-02f1280ea625.png">

Development
-----------

### API Documentation

Auto-generated API documentation is [here](https://manicmaniac.github.io/ApolloDeveloperKit).

### Run Example App

Since Example app is slightly modified version of [apollographql/frontpage-ios-app](https://github.com/apollographql/frontpage-ios-app),
you need to start [apollographql/frontpage-server](https://github.com/apollographql/frontpage-server) before runnning the app.

1. Open Xcode and select ApolloDeveloperKitExample scheme.
2. Run and open `http://localhost:8081` in Google Chrome.

License
-------

This software is distributed under the MIT license.
See LICENSE for more detail.
