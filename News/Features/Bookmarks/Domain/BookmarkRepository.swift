import Foundation
import Combine

protocol BookmarkRepository {
    var bookmarksPublisher: AnyPublisher<[Article], Never> { get }
    func isBookmarked(_ articleId: String) -> Bool
    func toggleBookmark(_ article: Article)
    func loadBookmarks()
}
