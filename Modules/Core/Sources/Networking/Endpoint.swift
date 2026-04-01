import Foundation

// MARK: - Endpoint Protocol
public protocol Endpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem]? { get }
    var body: (any Encodable & Sendable)? { get }
    var timeoutInterval: TimeInterval { get }
}

public extension Endpoint {
    var headers: [String: String] { [:] }
    var queryItems: [URLQueryItem]? { nil }
    var body: (any Encodable & Sendable)? { nil }
    var timeoutInterval: TimeInterval { 30 }
}

// MARK: - Empty Body
public struct EmptyBody: Encodable, Sendable {}


// MARK: - Empty Response
public struct EmptyResponse: Decodable, Sendable {}
