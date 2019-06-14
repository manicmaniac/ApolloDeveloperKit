//
//  RepositoryTableViewController.swift
//  ApolloDeveloperKitExample
//
//  Created by Ryosuke Ito on 6/14/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import UIKit

private typealias Repository = SearchRepositoriesQuery.Data.Search.Edge.Node.AsRepository

class RepositoryTableViewController: UITableViewController, UISearchBarDelegate {
    private let apolloClient: ApolloClient
    private let cellReuseIdentifier = "Cell"
    private var searchController: UISearchController!
    private var repositories = [Repository]()
    private var currentRequest: Cancellable?

    init(apolloClient: ApolloClient) {
        self.apolloClient = apolloClient
        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        let searchController = UISearchController(searchResultsController: nil)
        self.searchController = searchController
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.spellCheckingType = .no
        tableView.tableHeaderView = searchController.searchBar
        tableView.tableFooterView = UIView()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellReuseIdentifier)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
        configureCell(cell, forRowAt: indexPath)
        return cell
    }

    private func configureCell(_ cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        precondition(indexPath.section == 0)
        let repository = repositories[indexPath.row]
        cell.textLabel?.text = repository.nameWithOwner
        cell.detailTextLabel?.text = "Star: \(repository.stargazers.totalCount) Fork: \(repository.forkCount)"
    }

    private func presentAlertController(error: Error) {
        let alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }

    // MARK: - UISearchBarDelegate

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        guard let searchText = searchBar.text else { return }
        currentRequest?.cancel()
        let query = SearchRepositoriesQuery(searchText: searchText)
        currentRequest = apolloClient.fetch(query: query) { [weak self] result, error in
            switch error {
            case URLError.cancelled?:
                break
            case let error?:
                OperationQueue.main.addOperation { [weak self] in
                    self?.presentAlertController(error: error)
                }
            case nil:
                OperationQueue.main.addOperation { [weak self] in
                    self?.repositories = result?.data?.search.edges?.compactMap { edge in edge?.node?.asRepository } ?? []
                    self?.tableView.reloadData()
                }
            }
        }
    }
}
