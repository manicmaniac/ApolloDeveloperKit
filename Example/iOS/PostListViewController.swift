import UIKit
import Apollo

protocol PostListViewControllerDelegate: class {
    func postListViewControllerWantsToToggleConsoleRedirection(_ postListViewController: PostListViewController)
}

class PostListViewController: UITableViewController {
    var apollo: ApolloClient!
    var serverURL: URL?
    weak var delegate: PostListViewControllerDelegate?

    var posts: [AllPostsQuery.Data.Post?]? {
        didSet {
            tableView.reloadData()
        }
    }

    // MARK: - View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlDidChangeValue(_:)), for: .valueChanged)
        self.refreshControl = refreshControl
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadData(completion: nil)
    }

    // MARK: - Data loading

    var watcher: GraphQLQueryWatcher<AllPostsQuery>?

    func loadData(completion: (() -> Void)?) {
        watcher = apollo.watch(query: AllPostsQuery()) { result in
            switch result {
            case .success(let response):
                self.posts = response.data?.posts
            case .failure(let error):
                NSLog("Error while fetching query: \(error.localizedDescription)")
            }
            completion?()
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
        let alertController = UIAlertController(title: "IP address", message: serverURL?.absoluteString ?? "(unknown)", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Toggle console redirection", style: .default) { action in
            self.delegate?.postListViewControllerWantsToToggleConsoleRedirection(self)
        })
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    @objc private func refreshControlDidChangeValue(_ sender: UIRefreshControl) {
        loadData {
            sender.endRefreshing()
        }
    }
}

extension PostListViewController: PostTableViewCellDelegate {
    func postTableViewCell(_ postTableViewCell: PostTableViewCell, didPerformUpvote postId: Int) {
        apollo.perform(mutation: UpvotePostMutation(postId: postId)) { result in
            if case .failure(let error) = result {
                NSLog("Error while attempting to upvote post: \(error.localizedDescription)")
            }
        }
    }
}
