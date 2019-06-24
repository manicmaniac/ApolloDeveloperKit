import UIKit
import Apollo
import ApolloDeveloperKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let apollo: ApolloClient
    private let server: ApolloDebugServer

    override init() {
        // Change localhost to your machine's local IP address when running from a device
        let url = URL(string: "http://localhost:8080/graphql")!
        let networkTransport = DebuggableNetworkTransport(networkTransport: HTTPNetworkTransport(url: url))
        let cache = DebuggableNormalizedCache(cache: InMemoryNormalizedCache())
        let store = ApolloStore(cache: cache)
        apollo = ApolloClient(networkTransport: networkTransport, store: store)
        server = ApolloDebugServer(networkTransport: networkTransport, cache: cache)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        apollo.cacheKeyForObject = { $0["id"] }
        let navigationController = window!.rootViewController as! UINavigationController
        let postListViewController = navigationController.topViewController as! PostListViewController
        postListViewController.apollo = apollo
        server.start(port: 8081)
        return true
    }
}
