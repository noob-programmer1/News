import Foundation
import Combine

// MARK: - NewsFeedViewModel
final class NewsFeedViewModel: ViewModel {
    private let store = StateStore<FeedState>(FeedState())
    var statePublisher: ReadOnlyPublisher<FeedState> { store.publisher }
    var effectPublisher: EffectPublisher<FeedEffect> { effectSubject.eraseToAnyPublisher() }

    private let effectSubject = EffectSubject<FeedEffect>()
    private let paginator: NewsPaginator
    private let bookmarkRepository: BookmarkRepository
    private let trendingNotificationService: TrendingNotificationService
    private let trendingCount = 3

    private var searchDebounce: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()

    init(newsRepository: NewsRepository,
         bookmarkRepository: BookmarkRepository,
         trendingNotificationService: TrendingNotificationService) {
        self.bookmarkRepository = bookmarkRepository
        self.trendingNotificationService = trendingNotificationService
        self.paginator = NewsPaginator(newsRepository: newsRepository)

        bookmarkRepository.bookmarksPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.refreshBookmarkStatus($0) }
            .store(in: &cancellables)
    }

    func send(_ action: FeedAction) {
        switch action {
        case .fetchNews:
            fetchNews(showLoading: true)
        case .refresh:
            fetchNews(showLoading: false)
        case .loadNextPage:
            guard !paginator.isLoading, state.pagination == .idle else { return }
            store.update { $0.pagination = .loading }
            loadPage()
        case .selectCategory(let category):
            guard category != state.selectedCategory else { return }
            store.update { $0.selectedCategory = category }
            fetchNews(showLoading: true)
        case .search(let query):
            guard query != state.searchText else { return }
            store.update { $0.searchText = query }
            searchDebounce?.cancel()
            searchDebounce = Just(())
                .delay(for: .milliseconds(500), scheduler: DispatchQueue.main)
                .sink { [weak self] in self?.fetchNews(showLoading: true) }
        case .toggleBookmark(let articleView):
            bookmarkRepository.toggleBookmark(articleView.toDomain())
        }
    }

    private func fetchNews(showLoading: Bool) {
        paginator.reset()
        if showLoading || state.content.data == nil {
            store.update { $0.content = .loading }
        }
        store.update { $0.pagination = .idle }
        loadPage()
    }

    private func loadPage() {
        paginator.fetchPage(
            category: state.selectedCategory.apiValue,
            searchQuery: state.searchText
        ) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let page):
                self.applyArticles(page.articles, hasMore: page.hasMore)
            case .failure(let error):
                if self.state.content.data == nil {
                    self.store.update {
                        $0.content = .error(error.message)
                        $0.pagination = .idle
                    }
                } else {
                    self.store.update { $0.pagination = .idle }
                    self.effectSubject.send(.showError(error.message))
                }
            }
        }
    }

    private func applyArticles(_ articles: [Article], hasMore: Bool) {
        let bookmarkedIds = Set(articles.filter { bookmarkRepository.isBookmarked($0.stableId) }.map(\.stableId))
        let allViewStates = articles.map { $0.toViewState(isBookmarked: bookmarkedIds.contains($0.stableId)) }

        let data = FeedData(
            articles: Array(allViewStates.dropFirst(trendingCount)),
            trendingArticles: Array(allViewStates.prefix(trendingCount)),
            bookmarkedIds: bookmarkedIds
        )

        store.update {
            $0.content = articles.isEmpty ? .empty("No articles found") : .loaded(data)
            $0.pagination = hasMore ? .idle : .done
        }

        trendingNotificationService.scheduleTrendingNotification(articles: Array(articles.prefix(trendingCount)))
    }

    private func refreshBookmarkStatus(_ bookmarkedArticles: [Article]) {
        guard var data = state.content.data else { return }
        let bookmarkedIds = Set(bookmarkedArticles.map(\.stableId))
        data.bookmarkedIds = bookmarkedIds
        data.articles = data.articles.map { $0.withBookmark(bookmarkedIds.contains($0.id)) }
        data.trendingArticles = data.trendingArticles.map { $0.withBookmark(bookmarkedIds.contains($0.id)) }
        store.update { $0.content = .loaded(data) }
    }
}
