import Foundation
import Combine

// MARK: - Server Error Payload
private struct ServerErrorPayload: Decodable {
    let code: Int?
    let clientError: String?

    enum CodingKeys: String, CodingKey {
        case code
        case clientError = "client_error"
    }
}


// MARK: - HTTPClient
public final class HTTPClient: @unchecked Sendable {

    public let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let lock = NSLock()
    private var interceptors: [any RequestInterceptor] = []
    private let networkMonitor: NetworkMonitor
    private let tokenStore: TokenStore?


    public init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder? = nil,
        encoder: JSONEncoder? = nil,
        networkMonitor: NetworkMonitor,
        tokenStore: TokenStore? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.networkMonitor = networkMonitor
        self.tokenStore = tokenStore

        if let decoder {
            self.decoder = decoder
        } else {
            let d = JSONDecoder()
            d.keyDecodingStrategy = .convertFromSnakeCase
            d.dateDecodingStrategy = .iso8601
            self.decoder = d
        }

        if let encoder {
            self.encoder = encoder
        } else {
            let e = JSONEncoder()
            e.keyEncodingStrategy = .convertToSnakeCase
            e.dateEncodingStrategy = .iso8601
            self.encoder = e
        }
    }


    public func addInterceptor(_ interceptor: any RequestInterceptor) {
        lock.withLock { interceptors.append(interceptor) }
    }


    public func request<Response: Decodable & Sendable>(
        _ endpoint: some Endpoint,
        retryCount: Int = 2,
        retryDelay: TimeInterval = 1.0
    ) -> AnyPublisher<Response, NetworkError> {
        let urlRequest: URLRequest
        do {
            urlRequest = try buildURLRequest(for: endpoint)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }

        let decoder = self.decoder
        let tokenStore = self.tokenStore

        return session.dataTaskPublisher(for: urlRequest)
            .mapError { NetworkError.unknown($0.localizedDescription) }
            .flatMap { data, response -> AnyPublisher<Response, NetworkError> in
                guard let httpResponse = response as? HTTPURLResponse else {
                    return Fail(error: .unknown("Invalid response type.")).eraseToAnyPublisher()
                }

                let statusCode = httpResponse.statusCode

                switch statusCode {
                case 200...299:
                    if Response.self == EmptyResponse.self, let empty = EmptyResponse() as? Response {
                        return Just(empty).setFailureType(to: NetworkError.self).eraseToAnyPublisher()
                    }
                    return Just(data)
                        .decode(type: Response.self, decoder: decoder)
                        .mapError { .decodingFailed($0.localizedDescription) }
                        .eraseToAnyPublisher()

                case 417:
                    tokenStore?.handleTokenExpired()
                    return Fail(error: .tokenExpired).eraseToAnyPublisher()

                case 400...499:
                    return Fail(error: Self.mapHTTPError(statusCode: statusCode, data: data, decoder: decoder))
                        .eraseToAnyPublisher()

                case 500...599:
                    return Fail(error: .serverError(statusCode: statusCode)).eraseToAnyPublisher()

                default:
                    return Fail(error: .unknown("Unexpected status code: \(statusCode)")).eraseToAnyPublisher()
                }
            }
            .tryCatch { [weak self] (error: NetworkError) -> AnyPublisher<Response, NetworkError> in
                guard let self, retryCount > 0, error.isRetryable else {
                    throw error
                }
                return self.request(endpoint, retryCount: retryCount - 1, retryDelay: retryDelay * 2)
                    .delay(for: .seconds(retryDelay), scheduler: DispatchQueue.global())
                    .eraseToAnyPublisher()
            }
            .mapError { $0 as? NetworkError ?? .unknown($0.localizedDescription) }
            .eraseToAnyPublisher()
    }
}


extension HTTPClient {
    
    private func buildURLRequest(for endpoint: some Endpoint) throws(NetworkError) -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: true
        ) else {
            throw .invalidURL
        }
        
        if let queryItems = endpoint.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else { throw .invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeoutInterval
        
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if let body = endpoint.body, !(body is EmptyBody) {
            do {
                request.httpBody = try encodeBody(body)
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                throw .encodingFailed
            }
        }
        
        // Apply interceptors synchronously
        let currentInterceptors = lock.withLock { interceptors }
        for interceptor in currentInterceptors {
            interceptor.intercept(&request)
        }
        
        return request
    }
    
    private func encodeBody(_ body: any Encodable) throws -> Data {
        try encoder.encode(AnyEncodable(body))
    }
    
    private static func mapHTTPError(statusCode: Int, data: Data, decoder: JSONDecoder) -> NetworkError {
        if let payload = try? decoder.decode(ServerErrorPayload.self, from: data),
           let message = payload.clientError {
            return .clientError(statusCode: statusCode, message: message, fieldName: nil)
        }
        if let message = String(data: data, encoding: .utf8), !message.isEmpty {
            return .clientError(statusCode: statusCode, message: message, fieldName: nil)
        }
        return .clientError(statusCode: statusCode, message: "Request failed.", fieldName: nil)
    }
}
