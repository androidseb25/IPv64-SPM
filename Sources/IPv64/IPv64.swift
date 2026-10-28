import Foundation

/// Client for the IPv64.net REST API v2 (`https://ipv64.net/api/v2`).
///
/// The client is immutable and `Sendable`, so a single instance can be shared
/// freely across tasks and actors. Endpoints are grouped by area:
///
/// ```swift
/// let ipv64 = IPv64(apiKey: "…")
/// let me = try await ipv64.account.me()
/// let domains = try await ipv64.domains.list()
/// ```
///
/// To manage an account that shared its administration with you, derive a
/// client with ``actingAs(_:)``.
public final class IPv64: Sendable {
    /// The configuration this client was created with.
    public let configuration: Configuration

    let transport: any IPv64Transport

    /// Creates a client.
    ///
    /// - Parameters:
    ///   - configuration: API key, base URL and other options.
    ///   - transport: Performs the HTTP requests. Defaults to a `URLSession`-based transport.
    public init(
        configuration: Configuration,
        transport: any IPv64Transport = URLSessionTransport()
    ) {
        self.configuration = configuration
        self.transport = transport
    }

    /// Creates a client authenticating with the given API key.
    ///
    /// - Parameters:
    ///   - apiKey: API key from *Account > API* on ipv64.net. Pass `nil` to use only public endpoints.
    ///   - transport: Performs the HTTP requests. Defaults to a `URLSession`-based transport.
    public convenience init(
        apiKey: String?,
        transport: any IPv64Transport = URLSessionTransport()
    ) {
        self.init(configuration: Configuration(apiKey: apiKey), transport: transport)
    }

    /// Returns a client whose requests run in another account that granted you
    /// management access (header `X-IPv64-Act-As`).
    ///
    /// - Parameter account: Account ID or e-mail address of that account. `nil` acts as yourself.
    public func actingAs(_ account: String?) -> IPv64 {
        var configuration = configuration
        configuration.actAs = account
        return IPv64(configuration: configuration, transport: transport)
    }
}

extension IPv64 {
    /// Settings of an ``IPv64`` client.
    public struct Configuration: Sendable {
        /// How the API key is sent to the server.
        public enum Authentication: Sendable, Hashable {
            /// `Authorization: Bearer <API-Key>`
            case bearer
            /// `X-API-Key: <API-Key>`
            case apiKeyHeader
        }

        /// The production endpoint `https://ipv64.net/api/v2`.
        public static let productionBaseURL = URL(string: "https://ipv64.net/api/v2")!

        /// API key from *Account > API*. `nil` restricts the client to public endpoints.
        public var apiKey: String?
        /// How ``apiKey`` is transmitted.
        public var authentication: Authentication
        /// Base URL all endpoint paths are appended to.
        public var baseURL: URL
        /// Account ID or e-mail sent as `X-IPv64-Act-As`, see ``IPv64/actingAs(_:)``.
        public var actAs: String?
        /// Value of the `User-Agent` header.
        public var userAgent: String
        /// Timeout for a single request.
        public var timeoutInterval: TimeInterval

        public init(
            apiKey: String?,
            authentication: Authentication = .bearer,
            baseURL: URL = Configuration.productionBaseURL,
            actAs: String? = nil,
            userAgent: String = "IPv64-Swift/2.0",
            timeoutInterval: TimeInterval = 30
        ) {
            self.apiKey = apiKey
            self.authentication = authentication
            self.baseURL = baseURL
            self.actAs = actAs
            self.userAgent = userAgent
            self.timeoutInterval = timeoutInterval
        }
    }
}
