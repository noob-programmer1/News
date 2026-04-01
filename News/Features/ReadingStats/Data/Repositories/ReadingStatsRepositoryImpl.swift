import Foundation
import CoreData
import LocalPersistence

final class ReadingStatsRepositoryImpl: ReadingStatsRepository {
    private let store: ManagedObjectStore<ReadingSession>

    init(context: NSManagedObjectContext) {
        store = ManagedObjectStore(context: context, entityName: "ReadingSession")
    }

    func logSession(articleUrl: String, articleTitle: String, category: String?, duration: TimeInterval) {
        guard duration > 5 else { return } // ignore < 5s visits
        store.create { session in
            session.articleUrl = articleUrl
            session.articleTitle = articleTitle
            session.category = category
            session.duration = duration
            session.date = Date()
        }
        store.save()
    }

    func statsForCurrentWeek() -> ReadingStatsData {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let predicate = NSPredicate(format: "date >= %@", weekAgo as NSDate)
        let sessions = store.fetch(predicate: predicate, sortDescriptors: [NSSortDescriptor(key: "date", ascending: false)])

        let totalTime = sessions.reduce(0.0) { $0 + $1.duration }

        // Top categories
        var categoryCount: [String: Int] = [:]
        for session in sessions {
            let cat = session.category ?? "General"
            categoryCount[cat, default: 0] += 1
        }
        let topCategories = categoryCount.sorted { $0.value > $1.value }.map { (category: $0.key, count: $0.value) }

        return ReadingStatsData(
            articlesThisWeek: sessions.count,
            totalTimeThisWeek: totalTime,
            topCategories: topCategories
        )
    }
}
