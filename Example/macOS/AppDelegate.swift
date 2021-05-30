//
//  AppDelegate.swift
//  ApolloDeveloperKitExample-macOS
//
//  Created by Ryosuke Ito on 11/14/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Cocoa
import Apollo
#if DEBUG
import ApolloDeveloperKit
#endif

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    private var apollo: ApolloClient!
    #if DEBUG
    private var server: ApolloDebugServer!
    #endif

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let url = URL(string: "http://localhost:8080/graphql")!
        #if DEBUG
        let cache = DebuggableNormalizedCache(cache: InMemoryNormalizedCache())
        let store = ApolloStore(cache: cache)
        let interceptorProvider = LegacyInterceptorProvider(store: store)
        let networkTransport = DebuggableRequestChainNetworkTransport(interceptorProvider: interceptorProvider, endpointURL: url)
        server = ApolloDebugServer(networkTransport: networkTransport, cache: cache)
        server.enableConsoleRedirection = true
        try! server.start(port: 8081)
        #else
        let cache = InMemoryNormalizedCache()
        let store = ApolloStore(cache: cache)
        let interceptorProvider = LegacyInterceptorProvider()
        let networkTransport = RequestChainNetworkTransport(interceptorProvider: interceptorProvider, endpointURL: url)
        #endif
        apollo = ApolloClient(networkTransport: networkTransport, store: store)
        apollo.cacheKeyForObject = { $0["id"] }
        let postListViewController = NSApplication.shared.windows.first!.contentViewController as! PostListViewController
        postListViewController.apollo = apollo
        #if DEBUG
        postListViewController.serverURL = server.serverURL
        #endif
        postListViewController.delegate = self
        postListViewController.loadData(completion: nil)
    }
}

extension AppDelegate: PostListViewControllerDelegate {
    func postListViewControllerWantsToToggleConsoleRedirection(_ postListViewController: PostListViewController) {
        #if DEBUG
        server.enableConsoleRedirection = !server.enableConsoleRedirection
        #endif
    }
}
