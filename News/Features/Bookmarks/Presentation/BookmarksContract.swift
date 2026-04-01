import Foundation

// MARK: - BookmarksContract
struct BookmarksState {
    var bookmarks: [ArticleViewState] = []
    var isEmpty: Bool = true
}

enum BookmarksAction {
    case removeBookmark(ArticleViewState)
    case refreshProgress
}

enum BookmarksEffect {
    case bookmarkRemoved(String)
}
