import Foundation

// MARK: - ArticleViewState
struct ArticleViewState: Hashable {
    let id: String
    let title: String
    let description: String?
    let imageURL: String?
    let sourceName: String
    let timeAgo: String
    let articleURL: String
    let readingTime: String
    let publishedAt: String?
    let isBookmarked: Bool
    let readPercentage: Int?

    func withBookmark(_ bookmarked: Bool) -> ArticleViewState {
        ArticleViewState(
            id: id, title: title, description: description, imageURL: imageURL,
            sourceName: sourceName, timeAgo: timeAgo, articleURL: articleURL,
            readingTime: readingTime, publishedAt: publishedAt,
            isBookmarked: bookmarked, readPercentage: readPercentage
        )
    }

    func withReadPercentage(_ pct: Int?) -> ArticleViewState {
        ArticleViewState(
            id: id, title: title, description: description, imageURL: imageURL,
            sourceName: sourceName, timeAgo: timeAgo, articleURL: articleURL,
            readingTime: readingTime, publishedAt: publishedAt,
            isBookmarked: isBookmarked, readPercentage: pct
        )
    }

    func toDomain() -> Article {
        Article(
            id: id, title: title, description: description, content: nil,
            url: articleURL, image: imageURL, publishedAt: publishedAt,
            sourceName: sourceName
        )
    }
}

// MARK: - Domain -> Presentation
extension Article {
    func toViewState(isBookmarked: Bool = false, readPercentage: Int? = nil) -> ArticleViewState {
        let wordCount = [title, description, content]
            .compactMap { $0 }
            .joined(separator: " ")
            .split(separator: " ")
            .count
        let minutes = max(1, wordCount / 200)

        return ArticleViewState(
            id: stableId, title: title, description: description, imageURL: image,
            sourceName: sourceName, timeAgo: publishedDate?.timeAgo ?? "",
            articleURL: url, readingTime: "\(minutes) min read",
            publishedAt: publishedAt,
            isBookmarked: isBookmarked, readPercentage: readPercentage
        )
    }
}
