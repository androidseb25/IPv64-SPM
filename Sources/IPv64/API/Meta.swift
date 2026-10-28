import Foundation

extension IPv64 {
    /// API information, health and your public IP. These endpoints need no API key.
    public var meta: Meta { Meta(client: self) }

    /// Endpoints of the *Meta* area.
    public struct Meta: Sendable {
        let client: IPv64

        /// API info: name, version, documentation link and server time.
        ///
        /// `GET /`
        public func info() async throws -> APIInfo {
            try await client.send(Request(.get, "/", authorization: .none))
        }

        /// Health status of the API.
        ///
        /// `GET /health`
        public func health() async throws -> APIHealth {
            try await client.send(Request(.get, "/health", authorization: .none))
        }

        /// The public IP address the request came from.
        ///
        /// `GET /ip`
        public func ip() async throws -> PublicIPAddress {
            try await client.send(Request(.get, "/ip", authorization: .none))
        }

        /// The OpenAPI 3.1 document of the API.
        ///
        /// `GET /openapi.json`
        public func openAPIDocument() async throws -> JSONValue {
            try await client.sendUnwrapped(Request(.get, "/openapi.json", authorization: .none))
        }
    }
}

/// Result of ``IPv64/Meta/info()``.
public struct APIInfo: Codable, Hashable, Sendable {
    /// Name, e.g. `IPv64.net API`.
    public let name: String?
    /// Version, e.g. `2.0.0`.
    public let version: String?
    /// Link to the documentation.
    public let documentation: String?
    /// Server time.
    public let time: Date?
}

/// Result of ``IPv64/Meta/health()``.
public struct APIHealth: Codable, Hashable, Sendable {
    /// Status, e.g. `ok`.
    public let status: String?
    /// Version, e.g. `2.0.0`.
    public let version: String?
}

/// Result of ``IPv64/Meta/ip()``.
public struct PublicIPAddress: Codable, Hashable, Sendable {
    /// IP address, e.g. `203.0.113.10`.
    public let ip: String?
    /// Address family.
    public let family: IPFamily?
}

/// IP address family.
public struct IPFamily: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let ipv4: Self = "ipv4"
    public static let ipv6: Self = "ipv6"
}
