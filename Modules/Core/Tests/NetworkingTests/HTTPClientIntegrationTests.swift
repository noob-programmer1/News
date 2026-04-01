import Testing
import Foundation
import Combine
@testable import Networking

// MARK: - Mock URL Protocol

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

// MARK: - Test Endpoint

private struct TestEndpoint: Endpoint {
    typealias Response = TestResponse
    let path = "/test"
    let method: HTTPMethod = .get
}

private struct TestResponse: Decodable, Sendable, Equatable {
    let id: Int
    let name: String
}

// MARK: - Helper

private func makeClient() -> HTTPClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: config)

    return HTTPClient(
        baseURL: URL(string: "https://test.example.com")!,
        session: session,
        networkMonitor: NetworkMonitor()
    )
}

private func makeResponse(statusCode: Int, json: String) -> (HTTPURLResponse, Data) {
    let response = HTTPURLResponse(
        url: URL(string: "https://test.example.com/test")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: ["Content-Type": "application/json"]
    )!
    return (response, Data(json.utf8))
}

// MARK: - Tests

@Suite("HTTPClient Integration")
struct HTTPClientIntegrationTests {
    @Test("Successful 200 response decodes correctly")
    func successfulRequest() async throws {
        MockURLProtocol.requestHandler = { _ in
            makeResponse(statusCode: 200, json: #"{"id": 1, "name": "Test"}"#)
        }

        let client = makeClient()
        var result: TestResponse?
        var cancellables = Set<AnyCancellable>()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            client.request(TestEndpoint())
                .sink(
                    receiveCompletion: { _ in continuation.resume() },
                    receiveValue: { result = $0 }
                )
                .store(in: &cancellables)
        }

        #expect(result == TestResponse(id: 1, name: "Test"))
    }

    @Test("500 server error returns serverError")
    func serverError() async throws {
        MockURLProtocol.requestHandler = { _ in
            makeResponse(statusCode: 500, json: #"{"error": "internal"}"#)
        }

        let client = makeClient()
        var receivedError: NetworkError?
        var cancellables = Set<AnyCancellable>()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            client.request(TestEndpoint(), retryCount: 0)
                .sink(
                    receiveCompletion: {
                        if case .failure(let error) = $0 { receivedError = error }
                        continuation.resume()
                    },
                    receiveValue: { (_: TestResponse) in }
                )
                .store(in: &cancellables)
        }

        #expect(receivedError == .serverError(statusCode: 500))
    }

    @Test("400 client error maps message from JSON payload")
    func clientError() async throws {
        MockURLProtocol.requestHandler = { _ in
            makeResponse(statusCode: 400, json: #"{"client_error": "Invalid parameter"}"#)
        }

        let client = makeClient()
        var receivedError: NetworkError?
        var cancellables = Set<AnyCancellable>()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            client.request(TestEndpoint(), retryCount: 0)
                .sink(
                    receiveCompletion: {
                        if case .failure(let error) = $0 { receivedError = error }
                        continuation.resume()
                    },
                    receiveValue: { (_: TestResponse) in }
                )
                .store(in: &cancellables)
        }

        #expect(receivedError == .clientError(statusCode: 400, message: "Invalid parameter", fieldName: nil))
    }

    @Test("Retry succeeds after transient failure")
    func retryOnServerError() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            if callCount <= 1 {
                return makeResponse(statusCode: 503, json: #"{"error": "unavailable"}"#)
            }
            return makeResponse(statusCode: 200, json: #"{"id": 2, "name": "Recovered"}"#)
        }

        let client = makeClient()
        var result: TestResponse?
        var cancellables = Set<AnyCancellable>()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            client.request(TestEndpoint(), retryCount: 2, retryDelay: 0.1)
                .sink(
                    receiveCompletion: { _ in continuation.resume() },
                    receiveValue: { result = $0 }
                )
                .store(in: &cancellables)
        }

        #expect(result == TestResponse(id: 2, name: "Recovered"))
        #expect(callCount == 2)
    }

    @Test("Non-retryable errors fail immediately")
    func noRetryOnClientError() async throws {
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            return makeResponse(statusCode: 400, json: #"{"client_error": "Bad request"}"#)
        }

        let client = makeClient()
        var receivedError: NetworkError?
        var cancellables = Set<AnyCancellable>()

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            client.request(TestEndpoint(), retryCount: 2, retryDelay: 0.1)
                .sink(
                    receiveCompletion: {
                        if case .failure(let error) = $0 { receivedError = error }
                        continuation.resume()
                    },
                    receiveValue: { (_: TestResponse) in }
                )
                .store(in: &cancellables)
        }

        #expect(callCount == 1)
        #expect(receivedError == .clientError(statusCode: 400, message: "Bad request", fieldName: nil))
    }

    @Test("isRetryable returns correct values")
    func retryableErrors() {
        #expect(NetworkError.serverError(statusCode: 500).isRetryable == true)
        #expect(NetworkError.noInternet.isRetryable == true)
        #expect(NetworkError.unknown("timeout").isRetryable == true)
        #expect(NetworkError.clientError(statusCode: 400, message: "bad", fieldName: nil).isRetryable == false)
        #expect(NetworkError.tokenExpired.isRetryable == false)
        #expect(NetworkError.decodingFailed("x").isRetryable == false)
        #expect(NetworkError.invalidURL.isRetryable == false)
    }
}
