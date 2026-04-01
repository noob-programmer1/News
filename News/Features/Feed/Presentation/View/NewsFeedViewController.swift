import UIKit
import Combine

// MARK: - NewsFeedViewController
final class NewsFeedViewController: UITableViewController {
    fileprivate enum Section: Int, Hashable, CaseIterable {
        case trending = 0
        case articles = 1
        case loadingFooter = 2
    }

    fileprivate enum Item: Hashable {
        case trending([ArticleViewState])
        case article(ArticleViewState)
        case loadingFooter
    }

    private let viewModel: NewsFeedViewModel
    private let searchController = UISearchController(searchResultsController: nil)
    private let categoryFilterView = CategoryFilterView()
    private let loadingBackgroundView = LoadingView()
    private let emptyStateView = EmptyStateView()

    private var cancellables = Set<AnyCancellable>()
    private var lastRenderedData: FeedData?
    private weak var activeToast: UILabel?
    private lazy var diffableDataSource = makeDiffableDataSource()

    init(viewModel: NewsFeedViewModel) {
        self.viewModel = viewModel
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "News"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(image: UIImage(systemName: "chart.bar"), style: .plain, target: self, action: #selector(statsTapped)),
            UIBarButtonItem(image: UIImage(systemName: "moon.circle"), style: .plain, target: self, action: #selector(toggleDarkMode)),
        ]

        setupTableView()
        setupSearchController()
        setupCategoryFilter()
        setupRetry()
        tableView.dataSource = diffableDataSource
        bindViewModel()
        viewModel.send(.fetchNews)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = diffableDataSource.itemIdentifier(for: indexPath),
              case .article(let article) = item else { return }
        openArticleDetail(article)
    }

    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if let item = diffableDataSource.itemIdentifier(for: indexPath), case .article = item { return true }
        return false
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let item = diffableDataSource.itemIdentifier(for: indexPath),
              case .article = item,
              let data = viewModel.state.content.data,
              indexPath.row >= data.articles.count - 3,
              viewModel.state.pagination == .idle else { return }
        viewModel.send(.loadNextPage)
    }
}

// MARK: - Private
private extension NewsFeedViewController {
    func makeDiffableDataSource() -> UITableViewDiffableDataSource<Section, Item> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            guard let self else { return UITableViewCell() }
            switch item {
            case .trending(let articles):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: TrendingCell.reuseID, for: indexPath) as? TrendingCell else { return UITableViewCell() }
                cell.configure(with: articles)
                cell.onArticleSelected = { [weak self] in self?.openArticleDetail($0) }
                return cell
            case .article(let article):
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ArticleCell.reuseID, for: indexPath) as? ArticleCell else { return UITableViewCell() }
                cell.configure(with: article)
                cell.onBookmarkTapped = { [weak self] in self?.viewModel.send(.toggleBookmark(article)) }
                return cell
            case .loadingFooter:
                return tableView.dequeueReusableCell(withIdentifier: LoadingFooterCell.reuseID, for: indexPath)
            }
        }
    }

    func setupTableView() {
        tableView.register(ArticleCell.self, forCellReuseIdentifier: ArticleCell.reuseID)
        tableView.register(TrendingCell.self, forCellReuseIdentifier: TrendingCell.reuseID)
        tableView.register(LoadingFooterCell.self, forCellReuseIdentifier: LoadingFooterCell.reuseID)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 128, bottom: 0, right: 0)
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
    }

    func setupSearchController() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search articles..."
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        searchController.searchBar.searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
    }

    func setupCategoryFilter() {
        categoryFilterView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 48)
        categoryFilterView.onCategorySelected = { [weak self] in self?.viewModel.send(.selectCategory($0)) }
        tableView.tableHeaderView = categoryFilterView
    }

    func setupRetry() {
        emptyStateView.onRetry = { [weak self] in self?.viewModel.send(.refresh) }
    }



    func bindViewModel() {
        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.render($0) }
            .store(in: &cancellables)

        viewModel.effectPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.handleEffect($0) }
            .store(in: &cancellables)
    }

    func render(_ state: FeedState) {
        categoryFilterView.select(state.selectedCategory)

        switch state.content {
        case .idle:
            tableView.backgroundView = nil
        case .loading:
            if lastRenderedData != nil {
                tableView.backgroundView = nil
                applySnapshot(data: lastRenderedData, isPaginating: true)
            } else {
                tableView.backgroundView = loadingBackgroundView
                applySnapshot(data: nil, isPaginating: false)
            }
        case .loaded(let data):
            tableView.backgroundView = nil
            refreshControl?.endRefreshing()
            lastRenderedData = data
            applySnapshot(data: data, isPaginating: state.pagination == .loading)
        case .error(let msg):
            refreshControl?.endRefreshing()
            emptyStateView.configure(image: "exclamationmark.triangle", title: "Something went wrong", subtitle: msg, showRetry: true)
            tableView.backgroundView = emptyStateView
            applySnapshot(data: nil, isPaginating: false)
        case .empty(let msg):
            refreshControl?.endRefreshing()
            emptyStateView.configure(image: "magnifyingglass", title: "No articles found", subtitle: msg, showRetry: false)
            tableView.backgroundView = emptyStateView
            applySnapshot(data: nil, isPaginating: false)
        }
    }

    func applySnapshot(data: FeedData?, isPaginating: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        snapshot.appendSections(Section.allCases)

        if let data, !data.trendingArticles.isEmpty {
            snapshot.appendItems([.trending(data.trendingArticles)], toSection: .trending)
        }

        if let data {
            snapshot.appendItems(data.articles.map { .article($0) }, toSection: .articles)
        }

        if isPaginating {
            snapshot.appendItems([.loadingFooter], toSection: .loadingFooter)
        }

        diffableDataSource.defaultRowAnimation = .fade
        diffableDataSource.apply(snapshot, animatingDifferences: true)
    }

    func handleEffect(_ effect: FeedEffect) {
        switch effect {
        case .showError(let message):
            showToast(message)
        case .scrollToTop:
            tableView.setContentOffset(.zero, animated: true)
        }
    }

    @objc func statsTapped() {
        let statsVM = DependencyContainer.shared.makeReadingStatsViewModel()
        navigationController?.pushViewController(ReadingStatsViewController(viewModel: statsVM), animated: true)
    }

    @objc func toggleDarkMode() {
        guard let window = view.window else { return }
        window.overrideUserInterfaceStyle = window.overrideUserInterfaceStyle == .dark ? .light : .dark
        let icon = window.overrideUserInterfaceStyle == .dark ? "sun.max.circle" : "moon.circle"
        navigationItem.rightBarButtonItems?[1].image = UIImage(systemName: icon)
    }

    @objc func pullToRefresh() { viewModel.send(.refresh) }
    @objc func searchTextChanged() { viewModel.send(.search(searchController.searchBar.text ?? "")) }

    func openArticleDetail(_ articleView: ArticleViewState) {
        let detailVM = DependencyContainer.shared.makeArticleDetailViewModel(from: articleView)
        navigationController?.pushViewController(ArticleDetailViewController(viewModel: detailVM), animated: true)
    }

    func showToast(_ message: String) {
        activeToast?.removeFromSuperview()
        guard let window = view.window else { return }

        let toast = UILabel()
        toast.text = "  \(message)  "
        toast.font = .preferredFont(forTextStyle: .subheadline)
        toast.textColor = .white
        toast.backgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
        toast.textAlignment = .center
        toast.numberOfLines = 2
        toast.layer.cornerRadius = 10
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(toast)
        activeToast = toast

        let tabBarHeight = tabBarController?.tabBar.frame.height ?? 49

        NSLayoutConstraint.activate([
            toast.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 16),
            toast.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -16),
            toast.bottomAnchor.constraint(equalTo: window.bottomAnchor, constant: -(tabBarHeight + 16)),
            toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
        ])

        toast.transform = CGAffineTransform(translationX: 0, y: 100)
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            toast.transform = .identity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            UIView.animate(withDuration: 0.3, animations: {
                toast.transform = CGAffineTransform(translationX: 0, y: 100)
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
}
