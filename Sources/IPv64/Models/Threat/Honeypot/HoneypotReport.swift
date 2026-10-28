import Foundation

/// A report from a Honeypot64 sensor (request body of ``IPv64/Honeypot/submitReport(_:)``).
public struct HoneypotReport: Codable, Hashable, Sendable {
    /// Schema version of the report. Always `1`.
    public var schema: Int
    /// Report ID: `<sensor.id>-<period.start unix>`.
    public var reportID: String
    /// The reporting sensor.
    public var sensor: Sensor
    /// Reporting period.
    public var period: Period
    /// Attack sources (at most 5000).
    public var sources: [HoneypotReportSource]
    /// Samples (honeypot only), stored as daily totals.
    public var samples: HoneypotReportSamples?
    /// Number of entries the sensor dropped because of its limits.
    public var dropped: Int?

    /// Creates a report. `schema` defaults to `1`.
    public init(
        schema: Int = 1,
        reportID: String,
        sensor: Sensor,
        period: Period,
        sources: [HoneypotReportSource],
        samples: HoneypotReportSamples? = nil,
        dropped: Int? = nil
    ) {
        self.schema = schema
        self.reportID = reportID
        self.sensor = sensor
        self.period = period
        self.sources = sources
        self.samples = samples
        self.dropped = dropped
    }

    enum CodingKeys: String, CodingKey {
        case schema
        case reportID = "report_id"
        case sensor, period, sources, samples, dropped
    }

    /// The sensor that produced the report.
    public struct Sensor: Codable, Hashable, Sendable {
        /// UUID, fixed per installation (not the IP address). Sent exactly as given, so use the same
        /// spelling as in ``HoneypotReport/reportID`` (Node64 uses lowercase).
        public var id: String
        /// Sensor software version (at most 32 characters).
        public var version: String
        /// Sensor profile.
        public var profile: Profile
        /// Operating mode.
        public var mode: Mode

        /// Creates a sensor description.
        public init(id: String, version: String, profile: Profile, mode: Mode) {
            self.id = id
            self.version = version
            self.profile = profile
            self.mode = mode
        }

        /// Sensor profile.
        public struct Profile: IPv64OpenEnum {
            public let rawValue: String
            public init(rawValue: String) { self.rawValue = rawValue }

            public static let minimal: Self = "minimal"
            public static let standard: Self = "standard"
            public static let full: Self = "full"
            public static let custom: Self = "custom"
        }

        /// Operating mode of a sensor.
        public struct Mode: IPv64OpenEnum {
            public let rawValue: String
            public init(rawValue: String) { self.rawValue = rawValue }

            public static let module: Self = "module"
            public static let headless: Self = "headless"
        }
    }

    /// Reporting period in UTC: `start` inclusive, `end` exclusive. At most 7 days; `end` at most 5 minutes in the future.
    public struct Period: Codable, Hashable, Sendable {
        /// Start of the period (inclusive).
        public var start: Date
        /// End of the period (exclusive).
        public var end: Date

        /// Creates a period.
        public init(start: Date, end: Date) {
            self.start = start
            self.end = end
        }
    }
}

/// One attack source in a ``HoneypotReport``.
public struct HoneypotReportSource: Codable, Hashable, Sendable {
    /// Public IPv4 or IPv6 address.
    public var ip: String
    /// Kind of attack, from a fixed list, e.g. `ssh:bruteforce`, `http:exploit:sqli`, `generic:portscan`.
    public var kind: String
    /// Service, e.g. `ssh`.
    public var service: String
    /// Targeted port (0 to 65535).
    public var port: Int
    /// Number of events (at least 1).
    public var count: Int
    /// First sighting.
    public var first: Date
    /// Last sighting.
    public var last: Date
    /// Origin of the data.
    public var source: Origin
    /// Rule that matched (at most 64 characters), e.g. `honeypot/ssh@1`.
    public var rule: String?
    /// Details (at most 256 characters).
    public var detail: String?

    /// Creates a source.
    public init(
        ip: String,
        kind: String,
        service: String,
        port: Int,
        count: Int,
        first: Date,
        last: Date,
        source: Origin,
        rule: String? = nil,
        detail: String? = nil
    ) {
        self.ip = ip
        self.kind = kind
        self.service = service
        self.port = port
        self.count = count
        self.first = first
        self.last = last
        self.source = source
        self.rule = rule
        self.detail = detail
    }

    /// Origin of a reported source.
    public struct Origin: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let honeypot: Self = "honeypot"
        public static let log: Self = "log"
        public static let syslog: Self = "syslog"
    }
}

/// Samples in a ``HoneypotReport`` (honeypot only), stored as daily totals. Every list holds at most 500 entries.
public struct HoneypotReportSamples: Codable, Hashable, Sendable {
    /// Tried credentials (at most 500).
    public var credentials: [Credential]?
    /// Requested paths (at most 500).
    public var paths: [Counted]?
    /// User agents (at most 500).
    public var userAgents: [Counted]?
    /// Payloads (at most 500).
    public var payloads: [Payload]?
    /// Tool fingerprints (at most 500). Keys not matching `ja4:<id>` or `hassh:<md5>` are dropped.
    public var fingerprints: [Counted]?

    /// Creates samples.
    public init(
        credentials: [Credential]? = nil,
        paths: [Counted]? = nil,
        userAgents: [Counted]? = nil,
        payloads: [Payload]? = nil,
        fingerprints: [Counted]? = nil
    ) {
        self.credentials = credentials
        self.paths = paths
        self.userAgents = userAgents
        self.payloads = payloads
        self.fingerprints = fingerprints
    }

    enum CodingKeys: String, CodingKey {
        case credentials, paths
        case userAgents = "user_agents"
        case payloads, fingerprints
    }

    /// A tried username/password combination.
    public struct Credential: Codable, Hashable, Sendable {
        /// Service.
        public var service: String
        /// Username (at most 256 characters).
        public var user: String
        /// Password (at most 256 characters).
        public var pass: String
        /// Number of attempts (at least 1).
        public var count: Int

        /// Creates a credential sample.
        public init(service: String, user: String, pass: String, count: Int) {
            self.service = service
            self.user = user
            self.pass = pass
            self.count = count
        }
    }

    /// A counted key (path, user agent or fingerprint).
    public struct Counted: Codable, Hashable, Sendable {
        /// The key (paths up to 1024 characters, user agents up to 256, fingerprints `ja4:…` / `hassh:…`).
        public var key: String
        /// Number of occurrences (at least 1).
        public var count: Int

        /// Creates a counted key.
        public init(key: String, count: Int) {
            self.key = key
            self.count = count
        }
    }

    /// A payload sample.
    public struct Payload: Codable, Hashable, Sendable {
        /// Lowercase hex SHA-256 of the payload (64 characters).
        public var sha256: String
        /// Base64 of the first bytes of the payload (at most 256 bytes).
        public var head: String
        /// Service.
        public var service: String
        /// Port (0 to 65535).
        public var port: Int
        /// Number of occurrences (at least 1).
        public var count: Int

        /// Creates a payload sample.
        public init(sha256: String, head: String, service: String, port: Int, count: Int) {
            self.sha256 = sha256
            self.head = head
            self.service = service
            self.port = port
            self.count = count
        }
    }
}

/// Result of submitting a ``HoneypotReport``.
public struct HoneypotReportAccepted: Codable, Hashable, Sendable {
    /// Number of stored sources.
    public let accepted: Int?
    /// Number of dropped sources or samples.
    public let rejected: Int?
    /// Counts per drop reason: `not_public`, `own_ip`, `unknown_kind`, `unknown_service`, `unknown_source`, `out_of_period`, `invalid_fingerprint`.
    public let rejectedReasons: [String: Int]?
    /// Report ID.
    public let reportID: String?
    /// `true` if the report ID was already known (HTTP 200; counts as success).
    public let duplicate: Bool?

    enum CodingKeys: String, CodingKey {
        case accepted, rejected
        case rejectedReasons = "rejected_reasons"
        case reportID = "report_id"
        case duplicate
    }
}
