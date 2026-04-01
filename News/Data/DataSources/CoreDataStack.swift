import Foundation
import CoreData

// MARK: - BookmarkedArticle
@objc(BookmarkedArticle)
final class BookmarkedArticle: NSManagedObject {
    @NSManaged var articleId: String
    @NSManaged var title: String
    @NSManaged var articleDescription: String?
    @NSManaged var url: String
    @NSManaged var urlToImage: String?
    @NSManaged var publishedAt: String?
    @NSManaged var sourceName: String?
    @NSManaged var bookmarkedAt: Date

    func toArticle() -> Article {
        Article(id: articleId, title: title, description: articleDescription, content: nil,
                url: url, image: urlToImage, publishedAt: publishedAt,
                sourceName: sourceName ?? "Unknown")
    }
}

// MARK: - CachedArticle
@objc(CachedArticle)
final class CachedArticle: NSManagedObject {
    @NSManaged var articleId: String
    @NSManaged var title: String
    @NSManaged var articleDescription: String?
    @NSManaged var url: String
    @NSManaged var urlToImage: String?
    @NSManaged var publishedAt: String?
    @NSManaged var sourceName: String?
    @NSManaged var htmlContent: String?
    @NSManaged var cachedAt: Date

    func toArticle() -> Article {
        Article(id: articleId, title: title, description: articleDescription, content: nil,
                url: url, image: urlToImage, publishedAt: publishedAt,
                sourceName: sourceName ?? "Unknown")
    }
}

// MARK: - ReadingSession
@objc(ReadingSession)
final class ReadingSession: NSManagedObject {
    @NSManaged var articleUrl: String
    @NSManaged var articleTitle: String
    @NSManaged var category: String?
    @NSManaged var duration: Double
    @NSManaged var date: Date
}

// MARK: - ReadProgress
@objc(ReadProgress)
final class ReadProgress: NSManagedObject {
    @NSManaged var articleUrl: String
    @NSManaged var scrollY: Double
    @NSManaged var contentHeight: Double
    @NSManaged var lastReadAt: Date
}
