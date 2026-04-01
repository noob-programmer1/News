import UIKit
import Combine

// MARK: - BookmarksViewController
final class BookmarksViewController: UITableViewController {
    private let viewModel: BookmarksViewModel
    private let emptyStateView = EmptyStateView()

    private var cancellables = Set<AnyCancellable>()

    init(viewModel: BookmarksViewModel) {
        self.viewModel = viewModel
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Bookmarks"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(ArticleCell.self, forCellReuseIdentifier: ArticleCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        emptyStateView.configure(image: "bookmark", title: "No bookmarks yet", subtitle: "Articles you bookmark will appear here.")
        tableView.backgroundView = emptyStateView
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.send(.refreshProgress)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.state.bookmarks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ArticleCell.reuseID, for: indexPath) as? ArticleCell else { return UITableViewCell() }
        let article = viewModel.state.bookmarks[indexPath.row]
        cell.configure(with: article)
        cell.onBookmarkTapped = { [weak self] in self?.viewModel.send(.removeBookmark(article)) }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let article = viewModel.state.bookmarks[indexPath.row]
        let detailVM = DependencyContainer.shared.makeArticleDetailViewModel(from: article)
        navigationController?.pushViewController(ArticleDetailViewController(viewModel: detailVM), animated: true)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            guard let self else { return }
            self.viewModel.send(.removeBookmark(self.viewModel.state.bookmarks[indexPath.row]))
            completion(true)
        }
        delete.image = UIImage(systemName: "bookmark.slash")
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - Private
private extension BookmarksViewController {
    func bindViewModel() {
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.tableView.backgroundView?.isHidden = !state.isEmpty
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}
