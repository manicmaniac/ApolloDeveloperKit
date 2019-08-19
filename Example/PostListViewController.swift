import UIKit
import Apollo

class PostListViewController: UITableViewController {
    var apollo: ApolloClient!
    var serverURL: URL!
    
    var posts: [AllPostsQuery.Data.Post]? {
        didSet {
            tableView.reloadData()
        }
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadData()
    }

    // MARK: - Data loading

    var watcher: GraphQLQueryWatcher<AllPostsQuery>?

    func loadData() {
        watcher = apollo.watch(query: AllPostsQuery()) { (result, error) in
            if let error = error {
                NSLog("Error while fetching query: \(error.localizedDescription)")
                return
            }

            self.posts = result?.data?.posts
        }
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? PostTableViewCell else {
            fatalError("Could not dequeue PostTableViewCell")
        }

        guard let post = posts?[indexPath.row] else {
            fatalError("Could not find post at row \(indexPath.row)")
        }

        cell.configure(with: post.fragments.postDetails)
        cell.delegate = self

        return cell
    }

    @IBAction private func actionButtonDidTouchUpInside(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "IP address", message: serverURL.absoluteString, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension PostListViewController: PostTableViewCellDelegate {
    func postTableViewCell(_ postTableViewCell: PostTableViewCell, didPerformUpvote postId: Int) {
        apollo.perform(mutation: UpvotePostMutation(postId: postId)) { (result, error) in
            if let error = error {
                NSLog("Error while attempting to upvote post: \(error.localizedDescription)")
            }
        }
    }
}
