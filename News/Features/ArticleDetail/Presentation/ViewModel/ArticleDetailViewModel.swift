import Foundation
import Combine

// MARK: - ArticleDetailViewModel
final class ArticleDetailViewModel: ViewModel {
    private let store: StateStore<ArticleDetailState>
    var statePublisher: ReadOnlyPublisher<ArticleDetailState> { store.publisher }
    var effectPublisher: EffectPublisher<ArticleDetailEffect> { effectSubject.eraseToAnyPublisher() }

    private let effectSubject = EffectSubject<ArticleDetailEffect>()
    private let article: Article
    private let bookmarkRepository: BookmarkRepository
    private let cacheRepository: ArticleCacheRepository
    private let readProgressRepository: ReadProgressRepository

    private var cancellables = Set<AnyCancellable>()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    init(article: Article,
         bookmarkRepository: BookmarkRepository,
         cacheRepository: ArticleCacheRepository,
         readProgressRepository: ReadProgressRepository,
         bookmarksPublisher: AnyPublisher<[Article], Never>) {
        self.article = article
        self.bookmarkRepository = bookmarkRepository
        self.cacheRepository = cacheRepository
        self.readProgressRepository = readProgressRepository

        let formattedDate = article.publishedDate.map { Self.dateFormatter.string(from: $0) } ?? ""
        self.store = StateStore(ArticleDetailState(
            title: article.title,
            sourceName: article.sourceName,
            formattedDate: formattedDate,
            articleDescription: article.description,
            articleURL: URL(string: article.url),
            articleRawURL: article.url,
            isBookmarked: bookmarkRepository.isBookmarked(article.stableId),
            cachedHTML: cacheRepository.cachedHTML(for: article.url)
        ))

        bookmarksPublisher
            .map { [stableId = article.stableId] in $0.contains { $0.stableId == stableId } }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isBookmarked in
                self?.store.update { $0.isBookmarked = isBookmarked }
            }
            .store(in: &cancellables)
    }

    func send(_ action: ArticleDetailAction) {
        switch action {
        case .toggleBookmark:
            bookmarkRepository.toggleBookmark(article)
        case .cacheHTML(let html):
            cacheRepository.cacheHTML(html, for: article.url)
            store.update { $0.cachedHTML = html }
        case .saveScrollPosition(let scrollY, let contentHeight):
            readProgressRepository.saveProgress(for: article.url, scrollY: scrollY, contentHeight: contentHeight)
        case .loadArticle:
            if let cached = state.cachedHTML {
                effectSubject.send(.loadCachedHTML(cached, baseURL: URL(string: article.url)))
            } else if let url = state.articleURL {
                effectSubject.send(.loadURL(url))
            }
        }
    }

    func savedScrollFraction() -> Double? {
        guard let progress = readProgressRepository.loadProgress(for: article.url),
              progress.contentHeight > 0 else { return nil }
        return progress.scrollY / progress.contentHeight
    }
}
