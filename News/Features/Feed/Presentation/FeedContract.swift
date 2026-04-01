import Foundation

enum ArticleCategory: String, CaseIterable {
    case general = "General"
    case world = "World"
    case nation = "Nation"
    case business = "Business"
    case technology = "Technology"
    case entertainment = "Entertainment"
    case sports = "Sports"
    case science = "Science"
    case health = "Health"

    var apiValue: String { rawValue.lowercased() }
}

struct FeedData {
    var articles: [ArticleViewState]
    var trendingArticles: [ArticleViewState]
    var bookmarkedIds: Set<String>
}

struct FeedState {
    var content: ContentState<FeedData> = .idle
    var pagination: PaginationState = .idle
    var selectedCategory: ArticleCategory = .general
    var searchText: String = ""
}

enum FeedAction {
    case fetchNews
    case refresh
    case loadNextPage
    case selectCategory(ArticleCategory)
    case search(String)
    case toggleBookmark(ArticleViewState)
}

enum FeedEffect {
    case showError(String)
    case scrollToTop
}
