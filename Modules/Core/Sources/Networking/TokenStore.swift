import Foundation

// MARK: - Notifications

public extension Notification.Name {
    static let tokenExpired = Notification.Name("TokenStore.tokenExpired")
}

// MARK: - Token Store
public final class TokenStore: Sendable {
    private let store: any KeyValueStore
    private let key: String

    public init(
        store: any KeyValueStore,
        key: String = "auth_token"
    ) {
        self.store = store
        self.key = key
    }

    public var token: String? {
        store.get(forKey: key)
    }

    public func setToken(_ token: String?) {
        if let token {
            store.set(token, forKey: key)
        } else {
            clear()
        }
    }

    public func clear() {
        store.remove(forKey: key)
    }

    public func handleTokenExpired() {
        store.remove(forKey: key)
        NotificationCenter.default.post(name: .tokenExpired, object: nil)
    }
}
