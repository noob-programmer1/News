import Foundation

struct ReadingStatsState {
    var articlesThisWeek: Int = 0
    var totalTimeFormatted: String = "0 min"
    var topCategories: [(name: String, count: Int)] = []
}

enum ReadingStatsAction {
    case loadStats
}

typealias ReadingStatsEffect = NoEffect
