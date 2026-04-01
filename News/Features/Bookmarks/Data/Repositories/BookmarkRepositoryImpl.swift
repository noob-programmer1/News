import Foundation
import Combine
import CoreData
import LocalPersistence

final class BookmarkRepositoryImpl: NSObject, BookmarkRepository {
    private let store: ManagedObjectStore<BookmarkedArticle>
    private let context: NSManagedObjectContext
    private let subject = CurrentValueSubject<[Article], Never>([])
    private var frc: NSFetchedResultsController<BookmarkedArticle>?

    var bookmarksPublisher: AnyPublisher<[Article], Never> {
        subject.eraseToAnyPublisher()
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        self.store = ManagedObjectStore(context: context, entityName: "BookmarkedArticle")
        super.init()
        setupFRC()
    }

    func isBookmarked(_ articleId: String) -> Bool {
        store.count(predicate: NSPredicate(format: "articleId == %@", articleId)) > 0
    }

    func toggleBookmark(_ article: Article) {
        if isBookmarked(article.stableId) {
            store.deleteAll(predicate: NSPredicate(format: "articleId == %@", article.stableId))
            store.save()
        } else {
            store.create { bookmark in
                bookmark.articleId = article.stableId
                bookmark.title = article.title
                bookmark.articleDescription = article.description
                bookmark.url = article.url
                bookmark.urlToImage = article.image
                bookmark.publishedAt = article.publishedAt
                bookmark.sourceName = article.sourceName
                bookmark.bookmarkedAt = Date()
            }
            store.save()
        }
    }

    func loadBookmarks() {
        try? frc?.performFetch()
        publish()
    }


    private func setupFRC() {
        let request = NSFetchRequest<BookmarkedArticle>(entityName: "BookmarkedArticle")
        request.sortDescriptors = [NSSortDescriptor(key: "bookmarkedAt", ascending: false)]

        frc = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        frc?.delegate = self
        try? frc?.performFetch()
        publish()
    }

    private func publish() {
        let articles = (frc?.fetchedObjects ?? []).map { $0.toArticle() }
        subject.send(articles)
    }
}

extension BookmarkRepositoryImpl: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<any NSFetchRequestResult>) {
        publish()
    }
}
