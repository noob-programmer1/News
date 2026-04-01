import Foundation
import Security

// MARK: - KeyValueStore Protocol
public protocol KeyValueStore: Sendable {
    func get<V: Decodable & Sendable>(forKey key: String) -> V?
    func set<V: Encodable & Sendable>(_ value: V, forKey key: String)
    func remove(forKey key: String)
}

// MARK: - UserDefaults Store
public struct UserDefaultsStore: KeyValueStore, @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func get<V: Decodable & Sendable>(forKey key: String) -> V? {
        if V.self == String.self  { return defaults.string(forKey: key) as? V }
        if V.self == Int.self     { return defaults.object(forKey: key) as? V }
        if V.self == Double.self  { return defaults.object(forKey: key) as? V }
        if V.self == Bool.self    { return defaults.object(forKey: key) as? V }

        // Codable fallback — stored as JSON Data.
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(V.self, from: data)
    }

    public func set<V: Encodable & Sendable>(_ value: V, forKey key: String) {
        switch value {
        case let v as String:  defaults.set(v, forKey: key); return
        case let v as Int:     defaults.set(v, forKey: key); return
        case let v as Double:  defaults.set(v, forKey: key); return
        case let v as Bool:    defaults.set(v, forKey: key); return
        default: break
        }

        // Codable fallback.
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    public func remove(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}
