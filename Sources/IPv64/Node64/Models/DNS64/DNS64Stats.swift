import Foundation

extension Node64 {
    /// Time range of the statistics endpoints.
    public struct DNS64Range: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Last hour.
        public static let lastHour: Self = "1h"
        /// Last 24 hours (default).
        public static let last24Hours: Self = "24h"
        /// Last 7 days.
        public static let last7Days: Self = "7d"
    }

    /// Kind of a top list.
    public struct DNS64TopKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Most blocked domains.
        public static let blocked: Self = "blocked"
        /// Most requested allowed domains.
        public static let allowed: Self = "allowed"
        /// Most active clients.
        public static let clients: Self = "clients"
    }

    /// How a query was answered (status of a log row).
    public struct DNS64QueryStatus: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Resolved by an upstream server.
        public static let allowed: Self = "allowed"
        /// Answered from the cache.
        public static let cached: Self = "cached"
        /// Blocked by a list or rule.
        public static let blocked: Self = "blocked"
        /// Answered locally.
        public static let local: Self = "local"
        /// Failed.
        public static let error: Self = "error"
        /// Answered by a custom record.
        public static let custom: Self = "custom"
    }

    /// Transport a query arrived on, or an upstream uses.
    public struct DNS64Protocol: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Plain DNS over UDP.
        public static let udp: Self = "udp"
        /// Plain DNS over TCP.
        public static let tcp: Self = "tcp"
        /// DNS over HTTPS.
        public static let doh: Self = "doh"
        /// DNS over TLS.
        public static let dot: Self = "dot"
        /// DNS over QUIC.
        public static let doq: Self = "doq"
    }

    /// Whether the node's blocking is currently paused. Schema `DNS64Blocking`.
    public struct DNS64Blocking: Codable, Hashable, Sendable {
        /// `true` while blocking is paused.
        public let paused: Bool?
        /// `true` if blocking stays paused until ``Node64/DNS64/resume()``.
        public let untilResumed: Bool?
        /// End of a timed pause.
        public let pausedUntil: Date?

        enum CodingKeys: String, CodingKey {
            case paused
            case untilResumed = "until_resumed"
            case pausedUntil = "paused_until"
        }
    }

    /// State of the DNS service, result of ``Node64/DNS64/status()``.
    public struct DNS64Status: Codable, Hashable, Sendable {
        /// Software version.
        public let version: String?
        /// Listen address (`address:port`).
        public let listen: String?
        /// Start time of the DNS service.
        public let startedAt: Date?
        /// DNS server for local names (empty = none).
        public let router: String?
        /// Where `router` comes from: `config` or `auto`.
        public let routerSource: String?
        /// Days the query log is kept.
        public let retentionDays: Int?
        /// Pause state of blocking.
        public let blocking: DNS64Blocking?
    }

    /// Counters of a time range, nested in ``DNS64Summary``.
    public struct DNS64SummaryTotals: Codable, Hashable, Sendable {
        /// All queries.
        public let total: Int?
        /// Blocked queries.
        public let blocked: Int?
        /// Queries answered from the cache.
        public let cached: Int?
        /// Distinct clients.
        public let clients: Int?
        /// Average upstream response time in milliseconds.
        public let avgUpstreamMs: Double?
        /// Log entries dropped because the log queue was full.
        public let droppedLogEntries: Int?
    }

    /// Key figures of a time range. Schema `DNS64Summary`.
    public struct DNS64Summary: Codable, Hashable, Sendable {
        /// Counters of the requested range.
        public let summary: DNS64SummaryTotals?
        /// Number of blocklist rules loaded.
        public let blocklistSize: Int?
        /// When the blocklists were loaded.
        public let listsLoadedAt: Date?
        /// Cache counters.
        public let cache: DNS64Cache?
        /// Seconds since the DNS service started.
        public let uptimeSeconds: Int?
        /// Software version.
        public let version: String?
    }

    /// One bar of ``DNS64Timeline``.
    public struct DNS64TimelineBucket: Codable, Hashable, Sendable {
        /// Start of the bucket as Unix time in milliseconds.
        public let t: Int?
        /// Queries in the bucket.
        public let total: Int?
        /// Blocked queries in the bucket.
        public let blocked: Int?

        /// Start of the bucket as a date.
        public var date: Date? { t.map { Date(timeIntervalSince1970: Double($0) / 1000) } }
    }

    /// Queries over time, result of ``Node64/DNS64/timeline(range:)``.
    public struct DNS64Timeline: Codable, Hashable, Sendable {
        /// Bar width in milliseconds (1h: 2 min, 24h: 30 min, 7d: 4 h).
        public let stepMs: Int?
        /// The bars.
        public let buckets: [DNS64TimelineBucket]?
    }

    /// Entry of a top list. Schema `DNS64TopItem`.
    public struct DNS64TopItem: Codable, Hashable, Sendable, Identifiable {
        /// Domain or client address.
        public let name: String?
        /// Host name of a client, if known.
        public let hostname: String?
        /// Number of queries.
        public let count: Int?
        /// Number of blocked queries (client lists).
        public let blocked: Int?

        /// Identifier for `Identifiable` (the name).
        public var id: String { name ?? "" }
    }

    /// One query of the log. Schema `DNS64LogRow`.
    public struct DNS64LogRow: Codable, Hashable, Sendable {
        /// Time as Unix time in milliseconds.
        public let t: Int?
        /// Client address.
        public let client: String?
        /// Client name (PTR lookup at the router).
        public let clientName: String?
        /// Queried domain.
        public let domain: String?
        /// Record type of the query, e.g. `A`.
        public let qtype: String?
        /// How the query was answered.
        public let status: DNS64QueryStatus?
        /// Blocklist or hint, e.g. `released:<list>`, `group:<domain>`, `cat:<category>`, `off:hold`, `forward:<domain>`.
        public let reason: String?
        /// DNS response code.
        public let rcode: String?
        /// Upstream that answered.
        public let upstream: String?
        /// Response time in milliseconds.
        public let ms: Double?
        /// Transport of the query.
        public let proto: DNS64Protocol?
        /// Device group of the client.
        public let group: String?

        /// Time of the query as a date.
        public var date: Date? { t.map { Date(timeIntervalSince1970: Double($0) / 1000) } }
    }

    /// Page of the query log, result of ``Node64/DNS64/log(status:query:limit:offset:group:)``.
    public struct DNS64Log: Codable, Hashable, Sendable {
        /// Rows, newest first.
        public let rows: [DNS64LogRow]?
        /// Total number of matching rows.
        public let total: Int?
    }
}
