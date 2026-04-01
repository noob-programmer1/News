import Foundation

struct SourceDTO: Codable, Sendable {
    let id: String?
    let name: String?
    let url: String?
}

struct ArticleDTO: Codable, Sendable {
    let id: String?
    let title: String
    let description: String?
    let content: String?
    let url: String
    let image: String?
    let publishedAt: String?
    let source: SourceDTO?

    func toDomain() -> Article {
        Article(
            id: id,
            title: title,
            description: description,
            content: content,
            url: url,
            image: image,
            publishedAt: publishedAt,
            sourceName: source?.name ?? "Unknown"
        )
    }
}
