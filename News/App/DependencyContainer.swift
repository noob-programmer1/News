import Foundation
import Networking
import LocalPersistence

// MARK: - DependencyContainer
final class DependencyContainer {
    static let shared = DependencyContainer()

    private var singletons: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]

    private init() { registerAll() }

    func register<T>(_ instance: T) {
        singletons[key(for: T.self)] = instance
    }

    func factory<T>(_ create: @escaping () -> T) {
        factories[key(for: T.self)] = create
    }

    func resolve<T>() -> T {
        let k = key(for: T.self)
        if let s = singletons[k] as? T { return s }
        if let f = factories[k], let i = f() as? T { return i }
        fatalError("No dependency registered for \(T.self)")
    }

    private func key<T>(for type: T.Type) -> String { String(describing: type) }
}

// MARK: - Registration
private extension DependencyContainer {
    func registerAll() {
        let provider = PersistentContainerProvider(name: "News")
        let networkMonitor = NetworkMonitor()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let httpClient = HTTPClient(baseURL: URL(string: "https://gnews.io")!, decoder: decoder, networkMonitor: networkMonitor)

        let mainContext = provider.viewContext
        let bgContext = provider.newBackgroundContext()

        let bookmarkRepo = BookmarkRepositoryImpl(context: mainContext)
        let cacheRepo = ArticleCacheRepositoryImpl(context: bgContext)

        register(provider as PersistentContainerProvider)
        register(networkMonitor as NetworkMonitor)
        register(httpClient as HTTPClient)
        register(bookmarkRepo as BookmarkRepositoryImpl)
        register(bookmarkRepo as BookmarkRepository)
        register(cacheRepo as ArticleCacheRepository)
        register(NewsRepositoryImpl(client: httpClient) as NewsRepository)
        register(TrendingNotificationServiceImpl() as TrendingNotificationService)

        factory { ReadProgressRepositoryImpl(context: bgContext) as ReadProgressRepository }
        factory { MockCommentRepository() as CommentRepository }
        factory { ReadingStatsRepositoryImpl(context: bgContext) as ReadingStatsRepository }
    }
}

// MARK: - Factory Methods
extension DependencyContainer {
    func makeNewsFeedViewModel() -> NewsFeedViewModel {
        NewsFeedViewModel(
            newsRepository: resolve(), bookmarkRepository: resolve(),
            trendingNotificationService: resolve()
        )
    }

    func makeBookmarksViewModel() -> BookmarksViewModel {
        BookmarksViewModel(bookmarkRepository: resolve(), readProgressRepository: resolve())
    }

    func makeArticleDetailViewModel(article: Article) -> ArticleDetailViewModel {
        let bookmarkRepo: BookmarkRepositoryImpl = resolve()
        return ArticleDetailViewModel(
            article: article, bookmarkRepository: bookmarkRepo,
            cacheRepository: resolve(), readProgressRepository: resolve(),
            bookmarksPublisher: bookmarkRepo.bookmarksPublisher
        )
    }

    func makeArticleDetailViewModel(from viewState: ArticleViewState) -> ArticleDetailViewModel {
        makeArticleDetailViewModel(article: viewState.toDomain())
    }

    func makeCommentsViewController(articleId: String) -> CommentsViewController {
        CommentsViewController(articleId: articleId, commentRepository: resolve())
    }

    func makeReadingStatsViewModel() -> ReadingStatsViewModel {
        ReadingStatsViewModel(repository: resolve())
    }

    func logReadingSession(articleUrl: String, articleTitle: String, category: String?, duration: TimeInterval) {
        let repo: ReadingStatsRepository = resolve()
        repo.logSession(articleUrl: articleUrl, articleTitle: articleTitle, category: category, duration: duration)
    }
}

// MARK: - @Injected
@propertyWrapper
struct Injected<T> {
    var wrappedValue: T { DependencyContainer.shared.resolve() }
}
