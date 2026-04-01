import Testing
import Foundation
import Combine
import LocalPersistence
@testable import News

@Suite("BookmarkRepository – CoreData Integration")
struct BookmarkRepositoryTests {
    private func makeRepo() -> BookmarkRepositoryImpl {
        let provider = PersistentContainerProvider(name: "Test", inMemory: true)
        return BookmarkRepositoryImpl(context: provider.viewContext)
    }

    private let testArticle = Article(
        id: "test-1", title: "Test Article", description: "A test description",
        content: nil, url: "https://example.com/test", image: nil,
        publishedAt: "2026-04-01T10:00:00Z", sourceName: "TestSource"
    )

    private let testArticle2 = Article(
        id: "test-2", title: "Second Article", description: "Another description",
        content: nil, url: "https://example.com/test2", image: "https://example.com/img.jpg",
        publishedAt: "2026-03-31T08:00:00Z", sourceName: "Source2"
    )

    @Test("Adding a bookmark persists it")
    func addBookmark() {
        let repo = makeRepo()
        #expect(repo.isBookmarked(testArticle.stableId) == false)
        repo.toggleBookmark(testArticle)
        #expect(repo.isBookmarked(testArticle.stableId) == true)
    }

    @Test("Removing a bookmark deletes it")
    func removeBookmark() {
        let repo = makeRepo()
        repo.toggleBookmark(testArticle)
        repo.toggleBookmark(testArticle)
        #expect(repo.isBookmarked(testArticle.stableId) == false)
    }

    @Test("Bookmarks publisher emits on changes")
    func publisherEmits() async throws {
        let repo = makeRepo()
        var received: [Article] = []
        var cancellables = Set<AnyCancellable>()

        repo.bookmarksPublisher
            .sink { received = $0 }
            .store(in: &cancellables)

        repo.toggleBookmark(testArticle)
        try await Task.sleep(for: .milliseconds(100))
        #expect(received.count == 1)

        repo.toggleBookmark(testArticle2)
        try await Task.sleep(for: .milliseconds(100))
        #expect(received.count == 2)
    }

    @Test("Multiple articles tracked independently")
    func multipleArticles() {
        let repo = makeRepo()
        repo.toggleBookmark(testArticle)
        repo.toggleBookmark(testArticle2)

        #expect(repo.isBookmarked(testArticle.stableId) == true)
        #expect(repo.isBookmarked(testArticle2.stableId) == true)
        #expect(repo.isBookmarked("nonexistent") == false)
    }
}
