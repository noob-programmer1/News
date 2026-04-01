import Foundation

// MARK: - ContentState
enum ContentState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)
    case empty(String)

    var isLoading: Bool { if case .loading = self { return true }; return false }
    var data: T? { if case .loaded(let d) = self { return d }; return nil }
    var errorMessage: String? { if case .error(let m) = self { return m }; return nil }
    var emptyMessage: String? { if case .empty(let m) = self { return m }; return nil }
}

// MARK: - PaginationState
enum PaginationState {
    case idle
    case loading
    case done
}
