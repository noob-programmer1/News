import Foundation
import Combine
import Networking


final class NewsPaginator {
    private let newsRepository: NewsRepository

    private var allArticles: [Article] = []
    private var seenIds = Set<String>()
    private var currentPage = 1
    private var totalArticles = 0
    private(set) var isLoading = false

    private var cancellable: AnyCancellable?

    var hasMorePages: Bool { allArticles.count < totalArticles }
    var articles: [Article] { allArticles }

    init(newsRepository: NewsRepository) {
        self.newsRepository = newsRepository
    }

    func reset() {
        cancellable?.cancel()
        cancellable = nil
        allArticles = []
        seenIds = []
        currentPage = 1
        totalArticles = 0
        isLoading = false
    }

    /// Result passed back to the VM via completion.
    func fetchPage(
        category: String,
        searchQuery: String,
        completion: @escaping (Result<PaginationResult, PaginationError>) -> Void
    ) {
        guard !isLoading else { return }
        isLoading = true

        let publisher: NetworkResult<NewsResult>
        if !searchQuery.isEmpty {
            publisher = newsRepository.searchNews(query: searchQuery, page: currentPage)
        } else {
            publisher = newsRepository.fetchTopHeadlines(category: category, page: currentPage)
        }

        cancellable = publisher
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    guard let self else { return }
                    self.isLoading = false

                    if case .failure(let error) = result {
                        completion(.failure(.network(error.localizedDescription)))
                    }
                },
                receiveValue: { [weak self] result in
                    guard let self else { return }
                    self.isLoading = false
                    self.totalArticles = result.totalArticles
                    self.currentPage += 1
                    self.appendNew(result.articles)

                    completion(.success(PaginationResult(
                        articles: self.allArticles,
                        hasMore: self.hasMorePages
                    )))
                }
            )
    }

    private func appendNew(_ newArticles: [Article]) {
        for article in newArticles {
            if !seenIds.contains(article.stableId) {
                seenIds.insert(article.stableId)
                allArticles.append(article)
            }
        }
    }
}

struct PaginationResult {
    let articles: [Article]
    let hasMore: Bool
}

enum PaginationError: Error {
    case network(String)

    var message: String {
        switch self {
        case .network(let msg): return msg
        }
    }
}
