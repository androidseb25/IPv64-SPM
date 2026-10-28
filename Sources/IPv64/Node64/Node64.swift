import Foundation

/// Client for the local JSON API of a Node64 node in your own network.
///
/// Unlike ``IPv64``, every node runs at its own address, so the base URL is
/// required. The client is immutable and `Sendable`; share one instance per node.
///
/// ```swift
/// let node = Node64(baseURL: URL(string: "https://node.example.com/api")!, apiKey: "node64_…")
/// let checks = try await node.hc.checks.list()
/// ```
///
/// Models of this API are nested in `Node64` (for example ``Node64/Check``) so they
/// never collide with the ipv64.net models of the same name.
public final class Node64: Sendable {
    /// The configuration this client was created with.
    public let configuration: Configuration

    let transport: any IPv64Transport

    /// Creates a client.
    ///
    /// - Parameters:
    ///   - configuration: Node address, API key and other options.
    ///   - transport: Performs the HTTP requests. Defaults to a `URLSession`-based transport.
    public init(
        configuration: Configuration,
        transport: any IPv64Transport = URLSessionTransport()
    ) {
        self.configuration = configuration
        self.transport = transport
    }

    /// Creates a client for the node at `baseURL`.
    ///
    /// - Parameters:
    ///   - baseURL: API root of the node, e.g. `https://node.example.com/api`.
    ///   - apiKey: API key from *Einstellungen > API-Keys* (`node64_…`). Pass `nil` to use only public endpoints.
    ///   - transport: Performs the HTTP requests. Defaults to a `URLSession`-based transport.
    public convenience init(
        baseURL: URL,
        apiKey: String?,
        transport: any IPv64Transport = URLSessionTransport()
    ) {
        self.init(configuration: Configuration(baseURL: baseURL, apiKey: apiKey), transport: transport)
    }
}

extension Node64 {
    /// Settings of a ``Node64`` client.
    public struct Configuration: Sendable {
        /// API root of the node, e.g. `https://node.example.com/api`.
        public var baseURL: URL
        /// API key (`node64_…`), sent as `Authorization: Bearer`. `nil` restricts the client to public endpoints.
        public var apiKey: String?
        /// Name recorded in the node's audit log (header `X-Agent-Actor`).
        public var agentActor: String?
        /// Value of the `User-Agent` header.
        public var userAgent: String
        /// Timeout for a single request.
        public var timeoutInterval: TimeInterval

        public init(
            baseURL: URL,
            apiKey: String?,
            agentActor: String? = nil,
            userAgent: String = "IPv64-Swift/2.0 (Node64)",
            timeoutInterval: TimeInterval = 30
        ) {
            self.baseURL = baseURL
            self.apiKey = apiKey
            self.agentActor = agentActor
            self.userAgent = userAgent
            self.timeoutInterval = timeoutInterval
        }
    }
}
