import Testing
import Foundation
import Combine
@testable import News
import Networking

// MARK: - Mocks

final class MockNewsRepository: NewsRepository {
    var result: Result<NewsResult, NetworkError> = .success(NewsResult(totalArticles: 0, articles: []))

    func fetchTopHeadlines(category: String, page: Int) -> NetworkResult<NewsResult> {
        result.publisher.eraseToAnyPublisher()
    }

    func searchNews(query: String, page: Int) -> NetworkResult<NewsResult> {
        result.publisher.eraseToAnyPublisher()
    }
}

final class MockBookmarkRepository: BookmarkRepository {
    private var bookmarked: [Article] = []
    private let subject = CurrentValueSubject<[Article], Never>([])

    var bookmarksPublisher: AnyPublisher<[Article], Never> { subject.eraseToAnyPublisher() }

    func isBookmarked(_ articleId: String) -> Bool {
        bookmarked.contains { $0.stableId == articleId }
    }

    func toggleBookmark(_ article: Article) {
        if let i = bookmarked.firstIndex(where: { $0.stableId == article.stableId }) {
            bookmarked.remove(at: i)
        } else {
            bookmarked.append(article)
        }
        subject.send(bookmarked)
    }

    func loadBookmarks() {}
}

final class MockCacheRepository: ArticleCacheRepository {
    var cached: [Article] = []
    var htmlStore: [String: String] = [:]

    func cacheArticles(_ articles: [Article]) { cached = articles }
    func cachedArticles() -> [Article] { cached }
    func cacheHTML(_ html: String, for url: String) { htmlStore[url] = html }
    func cachedHTML(for url: String) -> String? { htmlStore[url] }
}

final class MockReadProgressRepository: ReadProgressRepository {
    var store: [String: (scrollY: Double, contentHeight: Double)] = [:]

    func saveProgress(for url: String, scrollY: Double, contentHeight: Double) {
        store[url] = (scrollY, contentHeight)
    }

    func loadProgress(for url: String) -> (scrollY: Double, contentHeight: Double)? {
        store[url]
    }
}

final class MockNotificationService: TrendingNotificationService {
    var notified: [[Article]] = []
    func requestPermission() {}
    func scheduleTrendingNotification(articles: [Article]) { notified.append(articles) }
}

// MARK: - Test Data

let sampleArticles: [Article] = [
    Article(id: "1", title: "Swift 6 Released", description: "Apple releases Swift 6.", content: "Full content about Swift 6 release with many words for testing reading time estimate.", url: "https://example.com/1", image: nil, publishedAt: "2026-04-01T10:00:00Z", sourceName: "TechNews"),
    Article(id: "2", title: "iOS 26 Announced", description: "Apple unveils iOS 26.", content: nil, url: "https://example.com/2", image: nil, publishedAt: "2026-03-31T08:00:00Z", sourceName: "AppleInsider"),
    Article(id: "3", title: "Mars Mission", description: "ISRO launches orbiter.", content: nil, url: "https://example.com/3", image: nil, publishedAt: "2026-03-30T06:00:00Z", sourceName: "SpaceDaily"),
    Article(id: "4", title: "IPL 2026", description: "Cricket season.", content: nil, url: "https://example.com/4", image: nil, publishedAt: "2026-03-29T12:00:00Z", sourceName: "ESPN"),
    Article(id: "5", title: "Markets Surge", description: "Stocks up.", content: nil, url: "https://example.com/5", image: nil, publishedAt: "2026-03-28T09:00:00Z", sourceName: "Bloomberg"),
]

// MARK: - Article Model Tests

@Suite("Article Domain Model")
struct ArticleModelTests {
    @Test("stableId uses id when present")
    func stableId() {
        let a = Article(id: "abc", title: "T", description: nil, content: nil, url: "https://x.com", image: nil, publishedAt: nil, sourceName: "S")
        #expect(a.stableId == "abc")
    }

    @Test("stableId falls back to url")
    func stableIdFallback() {
        let a = Article(id: nil, title: "T", description: nil, content: nil, url: "https://fallback.com", image: nil, publishedAt: nil, sourceName: "S")
        #expect(a.stableId == "https://fallback.com")
    }

    @Test("publishedDate parses ISO8601")
    func dateParses() {
        let a = Article(id: "1", title: "T", description: nil, content: nil, url: "u", image: nil, publishedAt: "2026-04-01T10:00:00Z", sourceName: "S")
        #expect(a.publishedDate != nil)
    }

    @Test("publishedDate handles fractional seconds")
    func dateFractional() {
        let a = Article(id: "1", title: "T", description: nil, content: nil, url: "u", image: nil, publishedAt: "2026-04-01T10:00:00.000Z", sourceName: "S")
        #expect(a.publishedDate != nil)
    }
}

// MARK: - ArticleDTO Tests

@Suite("ArticleDTO")
struct ArticleDTOTests {
    @Test("Decodes GNews JSON and maps to domain")
    func decodingAndMapping() throws {
        let json = """
        {"id":"abc","title":"Test","description":"Desc","content":"Body","url":"https://x.com","image":"https://img.com/1.jpg","publishedAt":"2026-04-01T10:00:00Z","source":{"id":"s","name":"Source","url":"https://s.com"}}
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(ArticleDTO.self, from: json)
        let article = dto.toDomain()

        #expect(article.id == "abc")
        #expect(article.title == "Test")
        #expect(article.sourceName == "Source")
        #expect(article.image == "https://img.com/1.jpg")
    }

    @Test("Missing source defaults to Unknown")
    func missingSource() throws {
        let json = #"{"title":"T","url":"https://x.com"}"#.data(using: .utf8)!
        let dto = try JSONDecoder().decode(ArticleDTO.self, from: json)
        #expect(dto.toDomain().sourceName == "Unknown")
    }
}

// MARK: - ArticleViewState Mapper Tests

@Suite("Article → ViewState Mapping")
struct ArticleViewStateTests {
    @Test("Maps all fields correctly")
    func mapping() {
        let a = sampleArticles[0]
        let vs = a.toViewState(isBookmarked: true)

        #expect(vs.id == "1")
        #expect(vs.title == "Swift 6 Released")
        #expect(vs.sourceName == "TechNews")
        #expect(vs.isBookmarked == true)
        #expect(vs.articleURL == "https://example.com/1")
    }

    @Test("Reading time computed from word count")
    func readingTime() {
        let a = Article(id: "1", title: "T", description: String(repeating: "word ", count: 600), content: nil, url: "u", image: nil, publishedAt: nil, sourceName: "S")
        let vs = a.toViewState()
        #expect(vs.readingTime == "3 min read")
    }

    @Test("Reading time minimum 1 min")
    func readingTimeMin() {
        let a = Article(id: "1", title: "Short", description: nil, content: nil, url: "u", image: nil, publishedAt: nil, sourceName: "S")
        let vs = a.toViewState()
        #expect(vs.readingTime == "1 min read")
    }
}

// MARK: - NewsFeedViewModel Tests

@Suite("NewsFeedViewModel")
struct NewsFeedViewModelTests {
    private func makeVM(
        articles: [Article] = sampleArticles,
        bookmark: MockBookmarkRepository = MockBookmarkRepository()
    ) -> (NewsFeedViewModel, MockNewsRepository, MockBookmarkRepository) {
        let repo = MockNewsRepository()
        repo.result = .success(NewsResult(totalArticles: articles.count, articles: articles))
        let vm = NewsFeedViewModel(
            newsRepository: repo, bookmarkRepository: bookmark,
            cacheRepository: MockCacheRepository(), networkMonitor: NetworkMonitor(),
            trendingNotificationService: MockNotificationService()
        )
        return (vm, repo, bookmark)
    }

    @Test("Fetch populates trending + articles via ContentState")
    func fetch() async throws {
        let (vm, _, _) = makeVM()
        vm.send(.fetchNews)
        try await Task.sleep(for: .milliseconds(200))

        let data = vm.state.content.data
        #expect(data != nil)
        #expect(data?.trendingArticles.count == 3)
        #expect(data?.articles.count == 2)
    }

    @Test("Error sets content to .error")
    func fetchError() async throws {
        let repo = MockNewsRepository()
        repo.result = .failure(.noInternet)
        let vm = NewsFeedViewModel(
            newsRepository: repo, bookmarkRepository: MockBookmarkRepository(),
            cacheRepository: MockCacheRepository(), networkMonitor: NetworkMonitor(),
            trendingNotificationService: MockNotificationService()
        )

        vm.send(.fetchNews)
        try await Task.sleep(for: .milliseconds(200))

        #expect(vm.state.content.errorMessage != nil)
    }

    @Test("Bookmark toggle updates bookmarkedIds in state")
    func bookmark() async throws {
        let (vm, _, _) = makeVM()
        vm.send(.fetchNews)
        try await Task.sleep(for: .milliseconds(200))

        let article = vm.state.content.data!.trendingArticles[0]
        vm.send(.toggleBookmark(article))
        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.state.content.data?.bookmarkedIds.contains(article.id) == true)
    }

    @Test("Category change re-fetches")
    func category() async throws {
        let (vm, _, _) = makeVM()
        vm.send(.fetchNews)
        try await Task.sleep(for: .milliseconds(200))

        vm.send(.selectCategory(.sports))
        try await Task.sleep(for: .milliseconds(200))

        #expect(vm.state.selectedCategory == .sports)
        #expect(vm.state.content.data != nil)
    }
}

// MARK: - BookmarksViewModel Tests

@Suite("BookmarksViewModel")
struct BookmarksViewModelTests {
    @Test("Reflects repository state")
    func binds() async throws {
        let repo = MockBookmarkRepository()
        let vm = BookmarksViewModel(bookmarkRepository: repo, readProgressRepository: MockReadProgressRepository())

        #expect(vm.state.isEmpty == true)

        repo.toggleBookmark(sampleArticles[0])
        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.state.bookmarks.count == 1)
        #expect(vm.state.isEmpty == false)
    }

    @Test("Remove bookmark via action")
    func remove() async throws {
        let repo = MockBookmarkRepository()
        repo.toggleBookmark(sampleArticles[0])

        let vm = BookmarksViewModel(bookmarkRepository: repo, readProgressRepository: MockReadProgressRepository())
        try await Task.sleep(for: .milliseconds(100))

        let articleVS = vm.state.bookmarks[0]
        vm.send(.removeBookmark(articleVS))
        try await Task.sleep(for: .milliseconds(100))

        #expect(vm.state.isEmpty == true)
    }
}

// MARK: - ArticleDetailViewModel Tests

@Suite("ArticleDetailViewModel")
struct ArticleDetailViewModelTests {
    @Test("State has correct initial values")
    func initialState() {
        let article = sampleArticles[0]
        let vm = ArticleDetailViewModel(
            article: article, bookmarkRepository: MockBookmarkRepository(),
            cacheRepository: MockCacheRepository(), readProgressRepository: MockReadProgressRepository(),
            bookmarksPublisher: Just([]).eraseToAnyPublisher()
        )

        #expect(vm.state.title == "Swift 6 Released")
        #expect(vm.state.sourceName == "TechNews")
        #expect(vm.state.articleURL != nil)
        #expect(vm.state.isBookmarked == false)
    }

    @Test("Toggle bookmark updates state reactively")
    func toggleBookmark() async throws {
        let repo = MockBookmarkRepository()
        let article = sampleArticles[0]
        let vm = ArticleDetailViewModel(
            article: article, bookmarkRepository: repo,
            cacheRepository: MockCacheRepository(), readProgressRepository: MockReadProgressRepository(),
            bookmarksPublisher: repo.bookmarksPublisher
        )

        vm.send(.toggleBookmark)
        try await Task.sleep(for: .milliseconds(100))
        #expect(vm.state.isBookmarked == true)
    }

    @Test("Cache HTML updates state")
    func cacheHTML() {
        let cache = MockCacheRepository()
        let article = sampleArticles[0]
        let vm = ArticleDetailViewModel(
            article: article, bookmarkRepository: MockBookmarkRepository(),
            cacheRepository: cache, readProgressRepository: MockReadProgressRepository(),
            bookmarksPublisher: Just([]).eraseToAnyPublisher()
        )

        vm.send(.cacheHTML("<html>test</html>"))
        #expect(vm.state.cachedHTML == "<html>test</html>")
        #expect(cache.htmlStore[article.url] == "<html>test</html>")
    }

    @Test("Scroll fraction computed correctly")
    func scrollFraction() {
        let progress = MockReadProgressRepository()
        let article = sampleArticles[0]
        progress.store[article.url] = (scrollY: 500, contentHeight: 1000)

        let vm = ArticleDetailViewModel(
            article: article, bookmarkRepository: MockBookmarkRepository(),
            cacheRepository: MockCacheRepository(), readProgressRepository: progress,
            bookmarksPublisher: Just([]).eraseToAnyPublisher()
        )

        #expect(vm.savedScrollFraction() == 0.5)
    }
}

// MARK: - DeepLink Tests

@Suite("DeepLinkRouter")
struct DeepLinkTests {
    @Test("Parses article deep link")
    func parseArticle() {
        let url = URL(string: "newsreader://article?url=https%3A%2F%2Fexample.com%2Fnews")!
        let link = DeepLink.parse(url)

        if case .article(let articleUrl) = link {
            #expect(articleUrl == "https://example.com/news")
        } else {
            Issue.record("Expected .article deep link")
        }
    }

    @Test("Returns nil for unknown scheme")
    func unknownScheme() {
        let url = URL(string: "https://example.com")!
        #expect(DeepLink.parse(url) == nil)
    }

    @Test("Returns nil for unknown host")
    func unknownHost() {
        let url = URL(string: "newsreader://settings")!
        #expect(DeepLink.parse(url) == nil)
    }
}

// MARK: - Date Extension Tests

@Suite("Date+TimeAgo")
struct DateTimeAgoTests {
    @Test("Relative time formatting")
    func timeAgo() {
        #expect(Date().timeAgo == "Just now")
        #expect(Date(timeIntervalSinceNow: -3600).timeAgo == "1h ago")
        #expect(Date(timeIntervalSinceNow: -172800).timeAgo == "2d ago")
    }
}

// MARK: - ContentState Tests

@Suite("ContentState")
struct ContentStateTests {
    @Test("isLoading returns correct value")
    func isLoading() {
        let loading: ContentState<String> = .loading
        let loaded: ContentState<String> = .loaded("data")
        #expect(loading.isLoading == true)
        #expect(loaded.isLoading == false)
    }

    @Test("data returns value when loaded")
    func data() {
        let loaded: ContentState<Int> = .loaded(42)
        let error: ContentState<Int> = .error("fail")
        #expect(loaded.data == 42)
        #expect(error.data == nil)
    }

    @Test("errorMessage returns message when error")
    func error() {
        let error: ContentState<Int> = .error("something broke")
        #expect(error.errorMessage == "something broke")
    }
}
