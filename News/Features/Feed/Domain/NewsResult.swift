import Foundation

struct NewsResult: Sendable {
    let totalArticles: Int
    let articles: [Article]
}
