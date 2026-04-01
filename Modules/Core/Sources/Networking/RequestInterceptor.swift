import Foundation
import UIKit

// MARK: - Request Interceptor
public protocol RequestInterceptor: Sendable {
    func intercept(_ request: inout URLRequest)
}

// MARK: - Auth Interceptor

/// Injects a Bearer / Token authentication header.
public struct AuthInterceptor: RequestInterceptor {
    public enum Scheme: Sendable {
        case bearer
        case token
        case custom(String)

        var prefix: String {
            switch self {
            case .bearer: "Bearer"
            case .token: "Token"
            case .custom(let value): value
            }
        }
    }

    private let tokenProvider: TokenStore
    private let scheme: Scheme

    public init(scheme: Scheme = .token, tokenProvider: TokenStore) {
        self.scheme = scheme
        self.tokenProvider = tokenProvider
    }

    public func intercept(_ request: inout URLRequest) {
        guard let token = tokenProvider.token else { return }
        request.setValue("\(scheme.prefix) \(token)", forHTTPHeaderField: "Authorization")
    }
}

// MARK: - Default Headers Interceptor

/// Injects platform info, app version, device ID, and accept headers.
public struct DefaultHeadersInterceptor: RequestInterceptor {
    private let appVersion: String
    private let deviceID: String
    private let platformName: String
    private let platformVersion: String
    private let extraHeaders: [String: String]

    public init(
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
        deviceID: String,
        platformName: String = "Apple",
        platformVersion: String,
        extraHeaders: [String: String] = [:]
    ) {
        self.appVersion = appVersion
        self.deviceID = deviceID
        self.platformName = platformName
        self.platformVersion = platformVersion
        self.extraHeaders = extraHeaders
    }

    public func intercept(_ request: inout URLRequest) {
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(appVersion, forHTTPHeaderField: "App-Version")
        request.setValue(platformName, forHTTPHeaderField: "Platform-Name")
        request.setValue(platformVersion, forHTTPHeaderField: "Platform-Version")
        request.setValue(deviceID, forHTTPHeaderField: "device-id")

        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}
