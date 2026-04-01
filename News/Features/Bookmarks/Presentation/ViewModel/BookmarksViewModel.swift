import Foundation
import Combine

// MARK: - BookmarksViewModel
final class BookmarksViewModel: ViewModel {
    private let store = StateStore<BookmarksState>(BookmarksState())
    var statePublisher: ReadOnlyPublisher<BookmarksState> { store.publisher }
    var effectPublisher: EffectPublisher<BookmarksEffect> { effectSubject.eraseToAnyPublisher() }

    private let effectSubject = EffectSubject<BookmarksEffect>()
    private let bookmarkRepository: BookmarkRepository
    private let readProgressRepository: ReadProgressRepository

    private var cancellables = Set<AnyCancellable>()

    init(bookmarkRepository: BookmarkRepository, readProgressRepository: ReadProgressRepository) {
        self.bookmarkRepository = bookmarkRepository
        self.readProgressRepository = readProgressRepository

        bookmarkRepository.bookmarksPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] articles in
                guard let self else { return }
                let viewStates = articles.map { article -> ArticleViewState in
                    var pct: Int? = nil
                    if let progress = self.readProgressRepository.loadProgress(for: article.url),
                       progress.contentHeight > 0 {
                        pct = min(100, Int((progress.scrollY / progress.contentHeight) * 100))
                    }
                    return article.toViewState(isBookmarked: true, readPercentage: pct)
                }
                self.store.update {
                    $0.bookmarks = viewStates
                    $0.isEmpty = viewStates.isEmpty
                }
            }
            .store(in: &cancellables)
    }

    func send(_ action: BookmarksAction) {
        switch action {
        case .removeBookmark(let viewState):
            bookmarkRepository.toggleBookmark(viewState.toDomain())
            effectSubject.send(.bookmarkRemoved(viewState.title))
        case .refreshProgress:
            updateReadProgress()
        }
    }

    private func updateReadProgress() {
        let updated = state.bookmarks.map { article -> ArticleViewState in
            guard let progress = readProgressRepository.loadProgress(for: article.articleURL),
                  progress.contentHeight > 0 else { return article }
            let pct = min(100, Int((progress.scrollY / progress.contentHeight) * 100))
            return article.withReadPercentage(pct)
        }
        store.update { $0.bookmarks = updated }
    }

}
