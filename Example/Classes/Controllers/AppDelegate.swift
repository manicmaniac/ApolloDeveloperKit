//
//  AppDelegate.swift
//  ApolloDeveloperKitExample
//
//  Created by Ryosuke Ito on 6/14/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import ApolloDeveloperKit
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private let apolloClient: ApolloClient
    private let apolloStore: ApolloStore
    private let apolloDebugServer: ApolloDebugServer

    override init() {
        let urlString = Bundle.main.object(forInfoDictionaryKey: "GithubAPIURL") as! String
        let url = URL(string: urlString)!
        let token = Bundle.main.object(forInfoDictionaryKey: "GithubAPIToken") as! String
        let configuration = URLSessionConfiguration.default.copy() as! URLSessionConfiguration
        configuration.httpAdditionalHeaders = ["Authorization": "token \(token)"]
        let networkTransport = DebuggableNetworkTransport(networkTransport: HTTPNetworkTransport(url: url, configuration: configuration, sendOperationIdentifiers: false))
        let cache = DebuggableInMemoryNormalizedCache()
        apolloStore = ApolloStore(cache: cache)
        apolloClient = ApolloClient(networkTransport: networkTransport, store: apolloStore)
        apolloDebugServer = ApolloDebugServer(cache: cache, networkTransport: networkTransport)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        window.rootViewController = RepositoryTableViewController(apolloClient: apolloClient)
        window.makeKeyAndVisible()
        apolloDebugServer.start(port: 8080)
        return true
    }
}
