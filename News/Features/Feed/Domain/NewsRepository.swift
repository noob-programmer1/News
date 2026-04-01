import Foundation
import Combine
import Networking

protocol NewsRepository {
    func fetchTopHeadlines(category: String, page: Int) -> NetworkResult<NewsResult>
    func searchNews(query: String, page: Int) -> NetworkResult<NewsResult>
}
