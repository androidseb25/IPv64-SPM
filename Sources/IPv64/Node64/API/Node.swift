import Foundation

extension Node64.Node {
    /// Availability of the node, without authentication (used by the Docker `HEALTHCHECK`).
    ///
    /// The node answers `503` with `{status: degraded, database: unreachable}` when it is
    /// unhealthy; that surfaces as ``Node64Error``.
    ///
    /// `GET /health`
    public func health() async throws -> Node64.Health {
        try await client.send(Request(.get, "/health", authorization: .none))
    }

    /// Version and start time of the node.
    ///
    /// `GET /version`
    public func version() async throws -> Node64.Version {
        try await client.send(Request(.get, "/version"))
    }

    /// Metrics of the core and all running modules in the Prometheus text format 0.0.4.
    ///
    /// Create a dedicated API key for Prometheus.
    ///
    /// `GET /metrics`
    public func metrics() async throws -> String {
        try await client.sendText(Request(.get, "/metrics"))
    }
}

extension Node64 {
    /// Result of ``Node64/Node/health()``.
    public struct Health: Codable, Hashable, Sendable {
        /// Status, e.g. `ok`.
        public let status: String?
        /// Version of the node software.
        public let version: String?
        /// Server time.
        public let time: Date?
    }

    /// Result of ``Node64/Node/version()``.
    public struct Version: Codable, Hashable, Sendable {
        /// Version of the node software.
        public let version: String?
        /// Start time of the node process.
        public let startedAt: Date?
        /// Host name of the node.
        public let hostname: String?
        /// Server time.
        public let time: Date?

        enum CodingKeys: String, CodingKey {
            case version
            case startedAt = "started_at"
            case hostname, time
        }
    }
}
