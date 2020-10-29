import UIKit
import Apollo
#if DEBUG
import ApolloDeveloperKit
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var apollo: ApolloClient!
    #if DEBUG
    private var server: ApolloDebugServer!
    #endif

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Change localhost to your machine's local IP address when running from a device
        let url = URL(string: "http://localhost:8080/graphql")!
        #if DEBUG
        let cache = DebuggableNormalizedCache(cache: InMemoryNormalizedCache())
        let store = ApolloStore(cache: cache)
        let interceptorProvider = LegacyInterceptorProvider(store: store)
        let underlyingNetworkTransport = RequestChainNetworkTransport(interceptorProvider: interceptorProvider, endpointURL: url)
        let networkTransport = DebuggableNetworkTransport(networkTransport: underlyingNetworkTransport)
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
        let navigationController = window!.rootViewController as! UINavigationController
        let postListViewController = navigationController.topViewController as! PostListViewController
        postListViewController.apollo = apollo
        #if DEBUG
        postListViewController.serverURL = server.serverURL
        #endif
        postListViewController.delegate = self
        return true
    }
}

extension AppDelegate: PostListViewControllerDelegate {
    func postListViewControllerWantsToToggleConsoleRedirection(_ postListViewController: PostListViewController) {
        #if DEBUG
        server.enableConsoleRedirection = !server.enableConsoleRedirection
        #endif
    }
}
