import Combine

public typealias NetworkResult<Success> = AnyPublisher<Success, NetworkError>

// MARK: - Type-erased Encodable wrapper
public struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    public init(_ value: any Encodable) {
        _encode = { encoder in try value.encode(to: encoder) }
    }

    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
