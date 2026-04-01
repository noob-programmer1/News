import Foundation

struct ReadingStatsData {
    let articlesThisWeek: Int
    let totalTimeThisWeek: TimeInterval
    let topCategories: [(category: String, count: Int)]
}

protocol ReadingStatsRepository {
    func logSession(articleUrl: String, articleTitle: String, category: String?, duration: TimeInterval)
    func statsForCurrentWeek() -> ReadingStatsData
}
