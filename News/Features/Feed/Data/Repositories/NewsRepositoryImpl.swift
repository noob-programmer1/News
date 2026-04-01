import Foundation
import Combine
import Networking

final class NewsRepositoryImpl: NewsRepository {
    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    func fetchTopHeadlines(category: String, page: Int) -> NetworkResult<NewsResult> {
        client.request(NewsEndpoint.topHeadlines(category: category, page: page))
            .map { (dto: NewsResponseDTO) in
                NewsResult(totalArticles: dto.totalArticles,
                           articles: dto.articles.map { $0.toDomain() })
            }
            .eraseToAnyPublisher()
    }

    func searchNews(query: String, page: Int) -> NetworkResult<NewsResult> {
        client.request(NewsEndpoint.search(query: query, page: page))
            .map { (dto: NewsResponseDTO) in
                NewsResult(totalArticles: dto.totalArticles,
                           articles: dto.articles.map { $0.toDomain() })
            }
            .eraseToAnyPublisher()
    }
}
