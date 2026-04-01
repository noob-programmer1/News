import Foundation
import CoreData
import LocalPersistence

final class ReadProgressRepositoryImpl: ReadProgressRepository {
    private let store: ManagedObjectStore<ReadProgress>

    init(context: NSManagedObjectContext) {
        store = ManagedObjectStore(context: context, entityName: "ReadProgress")
    }

    func saveProgress(for articleUrl: String, scrollY: Double, contentHeight: Double) {
        guard contentHeight > 0 else { return }

        let newFraction = scrollY / contentHeight

        if let existing = store.first(predicate: NSPredicate(format: "articleUrl == %@", articleUrl)) {
            let oldFraction = existing.contentHeight > 0 ? existing.scrollY / existing.contentHeight : 0
            guard newFraction > oldFraction else { return }
        }

        store.upsert(predicate: NSPredicate(format: "articleUrl == %@", articleUrl)) { progress in
            progress.articleUrl = articleUrl
            progress.scrollY = scrollY
            progress.contentHeight = contentHeight
            progress.lastReadAt = Date()
        }
        store.save()
    }

    func loadProgress(for articleUrl: String) -> (scrollY: Double, contentHeight: Double)? {
        guard let result = store.first(predicate: NSPredicate(format: "articleUrl == %@", articleUrl)) else {
            return nil
        }
        return (scrollY: result.scrollY, contentHeight: result.contentHeight)
    }
}
