import Foundation
import Combine

// MARK: - ReadingStatsViewModel
final class ReadingStatsViewModel: ViewModel {
    private let store = StateStore(ReadingStatsState())
    var statePublisher: ReadOnlyPublisher<ReadingStatsState> { store.publisher }

    private let repository: ReadingStatsRepository

    init(repository: ReadingStatsRepository) {
        self.repository = repository
    }

    func send(_ action: ReadingStatsAction) {
        switch action {
        case .loadStats:
            let data = repository.statsForCurrentWeek()
            let minutes = Int(data.totalTimeThisWeek / 60)
            let timeStr = minutes < 60 ? "\(minutes) min" : "\(minutes / 60)h \(minutes % 60)m"

            store.update {
                $0.articlesThisWeek = data.articlesThisWeek
                $0.totalTimeFormatted = timeStr
                $0.topCategories = data.topCategories.prefix(5).map { (name: $0.category, count: $0.count) }
            }
        }
    }
}
