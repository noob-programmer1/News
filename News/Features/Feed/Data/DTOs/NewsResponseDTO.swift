import Foundation

struct NewsResponseDTO: Decodable, Sendable {
    let totalArticles: Int
    let articles: [ArticleDTO]
}
