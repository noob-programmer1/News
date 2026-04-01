import Foundation

public enum NetworkError: Error, Sendable, Equatable {
    case noInternet
    case invalidURL
    case invalidData
    case encodingFailed
    case decodingFailed(String)
    case tokenExpired
    case serverError(statusCode: Int)
    case clientError(statusCode: Int, message: String, fieldName: String?)
    case unknown(String)
}

extension NetworkError {
    public var isRetryable: Bool {
        switch self {
        case .serverError, .noInternet, .unknown:
            return true
        case .invalidURL, .invalidData, .encodingFailed, .decodingFailed, .tokenExpired, .clientError:
            return false
        }
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noInternet:
            "No internet connection. Please check your network settings."
        case .invalidURL:
            "The request URL is invalid."
        case .invalidData:
            "The server returned invalid data."
        case .encodingFailed:
            "Failed to encode request body."
        case .decodingFailed(let detail):
            "Failed to decode response: \(detail)"
        case .tokenExpired:
            "Your session has expired. Please log in again."
        case .serverError(let code):
            "Server error (\(code)). Please try again later."
        case .clientError(_, let message, _):
            message
        case .unknown(let message):
            message
        }
    }
}
