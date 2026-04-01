import Foundation

struct ArticleDetailState {
    let title: String
    let sourceName: String
    let formattedDate: String
    let articleDescription: String?
    let articleURL: URL?
    let articleRawURL: String
    var isBookmarked: Bool = false
    var cachedHTML: String?
}

enum ArticleDetailAction {
    case toggleBookmark
    case cacheHTML(String)
    case saveScrollPosition(scrollY: Double, contentHeight: Double)
    case loadArticle
}

enum ArticleDetailEffect {
    case loadURL(URL)
    case loadCachedHTML(String, baseURL: URL?)
    case showError(String)
}
