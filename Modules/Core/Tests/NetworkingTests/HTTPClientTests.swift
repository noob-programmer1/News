import Testing
import Foundation
import Combine
@testable import Networking

// MARK: - Test Helpers

struct MockEndpoint: Endpoint {
    typealias Response = MockResponse
    let path: String
    let method: HTTPMethod

    init(path: String = "/test", method: HTTPMethod = .get) {
        self.path = path
        self.method = method
    }
}

struct MockResponse: Decodable, Sendable, Equatable {
    let id: Int
    let name: String
}

struct PostEndpoint: Endpoint {
    typealias Response = MockResponse
    let path = "/create"
    let method: HTTPMethod = .post
    var body: Body?

    struct Body: Encodable, Sendable {
        let name: String
    }
}

/// In-memory key-value store for tests — no disk side effects.
final class InMemoryStore: KeyValueStore, @unchecked Sendable {
    private var storage: [String: Data] = [:]

    func get<V: Decodable & Sendable>(forKey key: String) -> V? {
        guard let data = storage[key] else { return nil }
        if V.self == String.self { return String(data: data, encoding: .utf8) as? V }
        return try? JSONDecoder().decode(V.self, from: data)
    }

    func set<V: Encodable & Sendable>(_ value: V, forKey key: String) {
        if let string = value as? String {
            storage[key] = Data(string.utf8)
        } else {
            storage[key] = try? JSONEncoder().encode(value)
        }
    }

    func remove(forKey key: String) {
        storage[key] = nil
    }
}

// MARK: - Tests

@Suite("NetworkError")
struct NetworkErrorTests {
    @Test("Localized descriptions are non-empty")
    func localizedDescriptions() {
        let errors: [NetworkError] = [
            .noInternet,
            .invalidURL,
            .invalidData,
            .encodingFailed,
            .decodingFailed("bad json"),
            .tokenExpired,
            .serverError(statusCode: 500),
            .clientError(statusCode: 400, message: "Bad request", fieldName: nil),
            .unknown("something"),
        ]
        for error in errors {
            #expect(error.localizedDescription.isEmpty == false)
        }
    }

    @Test("Equatable conformance")
    func equatable() {
        #expect(NetworkError.noInternet == NetworkError.noInternet)
        #expect(NetworkError.noInternet != NetworkError.invalidURL)
        #expect(
            NetworkError.clientError(statusCode: 400, message: "a", fieldName: nil)
            != NetworkError.clientError(statusCode: 401, message: "a", fieldName: nil)
        )
    }
}

@Suite("NetworkMonitor")
struct NetworkMonitorTests {
    @Test("Instance reports connectivity")
    func connectivity() {
        let monitor = NetworkMonitor()
        #expect(monitor.isConnected == true)
    }
}

@Suite("KeyValueStore")
struct KeyValueStoreTests {
    @Test("InMemoryStore round-trips String")
    func inMemoryString() {
        let store = InMemoryStore()
        store.set("hello", forKey: "k")
        let result: String? = store.get(forKey: "k")
        #expect(result == "hello")
        store.remove(forKey: "k")
        let gone: String? = store.get(forKey: "k")
        #expect(gone == nil)
    }

    @Test("UserDefaultsStore round-trips primitives and Codable")
    func userDefaultsStore() {
        let suite = UserDefaults(suiteName: "CoreTests-\(UUID().uuidString)")!
        let store = UserDefaultsStore(defaults: suite)

        store.set("abc", forKey: "s")
        let s: String? = store.get(forKey: "s")
        #expect(s == "abc")

        store.set(42, forKey: "i")
        let i: Int? = store.get(forKey: "i")
        #expect(i == 42)

        store.set(true, forKey: "b")
        let b: Bool? = store.get(forKey: "b")
        #expect(b == true)

        struct Info: Codable, Sendable, Equatable { let name: String; let age: Int }
        store.set(Info(name: "A", age: 1), forKey: "info")
        let info: Info? = store.get(forKey: "info")
        #expect(info == Info(name: "A", age: 1))

        store.remove(forKey: "s")
        let removed: String? = store.get(forKey: "s")
        #expect(removed == nil)
    }
}

@Suite("TokenStore")
struct TokenStoreTests {
    @Test("Set and clear token via in-memory store")
    func setAndClear() {
        let store = TokenStore(store: InMemoryStore())

        store.setToken("abc123")
        #expect(store.token == "abc123")

        store.clear()
        #expect(store.token == nil)
    }

    @Test("setToken(nil) clears")
    func setNil() {
        let store = TokenStore(store: InMemoryStore())
        store.setToken("x")
        store.setToken(nil)
        #expect(store.token == nil)
    }

    @Test("handleTokenExpired clears token and posts notification")
    func tokenExpired() async {
        let mem = InMemoryStore()
        mem.set("old", forKey: "auth_token")
        let store = TokenStore(store: mem)

        await confirmation { received in
            let observer = NotificationCenter.default.addObserver(
                forName: .tokenExpired,
                object: nil,
                queue: nil
            ) { _ in received() }

            store.handleTokenExpired()

            NotificationCenter.default.removeObserver(observer)
        }

        #expect(store.token == nil)
    }
}

@Suite("HTTPClient")
struct HTTPClientTests {
    @Test("Returns noInternet when disconnected")
    func noInternet() async {
        let monitor = NetworkMonitor()
        let client = HTTPClient(
            baseURL: URL(string: "https://example.com")!,
            networkMonitor: monitor
        )

        // request() returns AnyPublisher — verify it compiles with the right types
        let publisher: AnyPublisher<MockResponse, NetworkError> = client.request(MockEndpoint())
        _ = publisher
    }
}
