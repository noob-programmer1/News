import Foundation
import CoreData
import LocalPersistence

final class ArticleCacheRepositoryImpl: ArticleCacheRepository {
    private let store: ManagedObjectStore<CachedArticle>

    init(context: NSManagedObjectContext) {
        store = ManagedObjectStore(context: context, entityName: "CachedArticle")
    }

    func cacheHTML(_ html: String, for articleUrl: String) {
        store.upsert(predicate: NSPredicate(format: "url == %@", articleUrl)) { cached in
            cached.url = articleUrl
            cached.htmlContent = html
            cached.cachedAt = Date()
        }
        store.save()
    }

    func cachedHTML(for articleUrl: String) -> String? {
        store.first(predicate: NSPredicate(format: "url == %@", articleUrl))?.htmlContent
    }
}
