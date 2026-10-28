import Foundation

extension Node64 {
    /// Conditional forwarding of a domain to other DNS servers. Schema `DNS64Forward`.
    public struct DNS64Forward: Codable, Hashable, Sendable, Identifiable {
        /// ID of the forward.
        public let id: Int
        /// Domain (applies with all subnames); a network like `192.168.0.0/16` becomes a reverse zone.
        public let domain: String
        /// Servers (1-8, tried in order): IP, IP:Port, `tls://`, `https://…/dns-query`, `quic://`.
        public let servers: [String]
        /// Comment.
        public let comment: String?
        /// Whether the forward is on.
        public let enabled: Bool?
        /// Creation time.
        public let createdAt: Date?
        /// Statistics per server (only returned by `GET`).
        public let state: [DNS64ForwardServerState]?
        /// Only this node (never synchronized in a cluster).
        public let localOnly: Bool?

        enum CodingKeys: String, CodingKey {
            case id, domain, servers, comment, enabled
            case createdAt = "created_at"
            case state
            case localOnly = "local_only"
        }
    }

    /// Statistics of one forward server (inline object of `DNS64Forward.state`).
    public struct DNS64ForwardServerState: Codable, Hashable, Sendable {
        /// Display label.
        public let label: String?
        /// Server URL.
        public let url: String?
        /// Number of requests.
        public let requests: Int?
        /// Number of errors.
        public let errors: Int?
        /// Average response time in milliseconds.
        public let avgMs: Double?
        /// Whether the server is healthy.
        public let healthy: Bool?
        /// Last error message.
        public let lastError: String?
        /// Time of the last error.
        public let lastErrorAt: Date?

        enum CodingKeys: String, CodingKey {
            case label, url, requests, errors
            case avgMs = "avg_ms"
            case healthy
            case lastError = "last_error"
            case lastErrorAt = "last_error_at"
        }
    }

    /// Writable fields of a forward. The on/off state is changed with enable/disable.
    public struct DNS64ForwardInput: Encodable, Hashable, Sendable {
        /// Domain or network.
        public var domain: String
        /// Servers (1-8, tried in order).
        public var servers: [String]
        /// Comment.
        public var comment: String?
        /// Only this node (never synchronized in a cluster).
        public var localOnly: Bool?

        /// Creates a forward input; optional fields left `nil` are not sent.
        public init(domain: String, servers: [String], comment: String? = nil, localOnly: Bool? = nil) {
            self.domain = domain
            self.servers = servers
            self.comment = comment
            self.localOnly = localOnly
        }

        enum CodingKeys: String, CodingKey {
            case domain, servers, comment
            case localOnly = "local_only"
        }
    }

    /// Result of ``Node64/DNS64/Forwards/test(_:)``.
    public struct DNS64ForwardTestResult: Codable, Hashable, Sendable {
        /// Whether the test succeeded.
        public let ok: Bool?
        /// DNS response code.
        public let rcode: String?
        /// Server that answered.
        public let server: String?
        /// Duration in milliseconds.
        public let ms: Double?
        /// Error message.
        public let error: String?
    }

    /// Rewrite of a name to another name. Schema `DNS64Rewrite`.
    public struct DNS64Rewrite: Codable, Hashable, Sendable, Identifiable {
        /// ID of the rewrite.
        public let id: Int
        /// Name to rewrite, also `*.domain`.
        public let name: String
        /// Target name.
        public let target: String
        /// Comment.
        public let comment: String?
        /// Whether the rewrite is on.
        public let enabled: Bool?
        /// Creation time.
        public let createdAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, name, target, comment, enabled
            case createdAt = "created_at"
        }
    }

    /// Writable fields of a rewrite. The on/off state is changed with enable/disable.
    public struct DNS64RewriteInput: Encodable, Hashable, Sendable {
        /// Name to rewrite, also `*.domain`.
        public var name: String
        /// Target name.
        public var target: String
        /// Comment.
        public var comment: String?

        /// Creates a rewrite input; optional fields left `nil` are not sent.
        public init(name: String, target: String, comment: String? = nil) {
            self.name = name
            self.target = target
            self.comment = comment
        }
    }

    /// Local DNS zone. Schema `DNS64Zone`.
    public struct DNS64Zone: Codable, Hashable, Sendable, Identifiable {
        /// ID of the zone.
        public let id: Int
        /// Zone name; a network like `192.168.1.0/24` becomes a reverse zone.
        public let name: String
        /// Unknown names answer NXDOMAIN (otherwise they go on to forwards/router).
        public let authoritative: Bool?
        /// Devices of the groups with a label are published as `<name>.<zone>`.
        public let devices: Bool?
        /// Comment.
        public let comment: String?
        /// Whether the zone is on.
        public let enabled: Bool?
        /// Creation time.
        public let createdAt: Date?
        /// Default TTL of new records (default 300).
        public let ttl: Int?
        /// SOA refresh (default 3600).
        public let refresh: Int?
        /// SOA retry (default 600).
        public let retry: Int?
        /// SOA expire (default 86400).
        public let expire: Int?
        /// TTL for "does not exist" (default 60).
        public let minimum: Int?
        /// SOA mail; empty means `hostmaster.<zone>`.
        public let hostmaster: String?
        /// Dynamic updates (RFC 2136) are on (read-only).
        public let dynamic: Bool?
        /// TSIG key name (read-only).
        public let tsigName: String?

        enum CodingKeys: String, CodingKey {
            case id, name, authoritative, devices, comment, enabled
            case createdAt = "created_at"
            case ttl, refresh, retry, expire, minimum, hostmaster, dynamic
            case tsigName = "tsig_name"
        }
    }

    /// Writable fields of a local zone. The on/off state is changed with enable/disable.
    public struct DNS64ZoneInput: Encodable, Hashable, Sendable {
        /// Zone name or network.
        public var name: String
        /// Unknown names answer NXDOMAIN.
        public var authoritative: Bool?
        /// Publish device labels as `<name>.<zone>`.
        public var devices: Bool?
        /// Comment.
        public var comment: String?
        /// Default TTL of new records.
        public var ttl: Int?
        /// SOA refresh.
        public var refresh: Int?
        /// SOA retry.
        public var retry: Int?
        /// SOA expire.
        public var expire: Int?
        /// TTL for "does not exist".
        public var minimum: Int?
        /// SOA mail.
        public var hostmaster: String?

        /// Creates a zone input; optional fields left `nil` are not sent.
        public init(
            name: String, authoritative: Bool? = nil, devices: Bool? = nil, comment: String? = nil,
            ttl: Int? = nil, refresh: Int? = nil, retry: Int? = nil, expire: Int? = nil,
            minimum: Int? = nil, hostmaster: String? = nil
        ) {
            self.name = name
            self.authoritative = authoritative
            self.devices = devices
            self.comment = comment
            self.ttl = ttl
            self.refresh = refresh
            self.retry = retry
            self.expire = expire
            self.minimum = minimum
            self.hostmaster = hostmaster
        }
    }
}
