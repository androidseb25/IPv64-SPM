import Foundation

extension Node64 {
    /// State of the trap services. Schema `Honeypot64Status`.
    public struct Honeypot64Status: Codable, Hashable, Sendable {
        /// Sensor version.
        public let version: String?
        /// Whether the sensor runs.
        public let running: Bool?
        /// Start time.
        public let startedAt: Date?
        /// Profile in use.
        public let profile: String?
        /// Port scan detection on.
        public let scan: Bool?
        /// Services with port and state.
        public let services: [Honeypot64Service]?
        /// Hints about skipped or shared ports.
        public let warnings: [Honeypot64Warning]?
        /// Counters of the sensor.
        public let counters: Honeypot64Counters?
        /// Events waiting to be written.
        public let buffered: Int?
        /// Events dropped in memory.
        public let dropped: Int?
        /// Report to ipv64.
        public let report: Honeypot64ReportStatus?
        /// Log sensor and syslog receiver.
        public let logs: Honeypot64LogStatus?

        enum CodingKeys: String, CodingKey {
            case version, running
            case startedAt = "started_at"
            case profile, scan, services, warnings, counters, buffered, dropped, report, logs
        }
    }

    /// Counters inline in ``Honeypot64Status``.
    public struct Honeypot64Counters: Codable, Hashable, Sendable {
        /// Connections.
        public let connections: Int?
        /// Login attempts.
        public let logins: Int?
        /// Events.
        public let events: Int?
        /// Dropped events.
        public let dropped: Int?
    }

    /// A trap service. Schema `Honeypot64Service`.
    public struct Honeypot64Service: Codable, Hashable, Sendable {
        /// Service name.
        public let service: String?
        /// Port.
        public let port: Int?
        /// Port open.
        public let listen: Bool?
        /// Why it is not open (in use, no permission).
        public let error: String?
        /// Connections since start.
        public let conns: Int?
    }

    /// Hint about a port. Schema `Honeypot64Warning`.
    public struct Honeypot64Warning: Codable, Hashable, Sendable {
        /// Service.
        public let service: String?
        /// Port.
        public let port: Int?
        /// Other part of the node (web, edge, dns64, cdn64 …).
        public let owner: String?
        /// Purpose of the port there.
        public let purpose: String?
        /// `true` = not opened (port in use); `false` = opened, the other part cannot use it later.
        public let skipped: Bool?
    }

    /// Report to ipv64. Schema `Honeypot64ReportStatus`.
    public struct Honeypot64ReportStatus: Codable, Hashable, Sendable {
        /// Opt-in `report` is on.
        public let enabled: Bool?
        /// Central ipv64 API key is set.
        public let keySet: Bool?
        /// `enabled` and `keySet`: reporting is active.
        public let active: Bool?
        /// Fixed sensor ID (UUID), only when enabled.
        public let sensorID: String?
        /// Last report accepted by ipv64.
        public let lastSuccess: Date?
        /// Reported up to.
        public let lastEnd: Date?
        /// Last error since start.
        public let lastError: String?
        /// Time of the last error.
        public let lastErrorAt: Date?
        /// Next run (only when active).
        public let nextAttempt: Date?
        /// Failed or rejected reports since start.
        public let errors: Int?
        /// Source IPs reported today.
        public let sourcesToday: Int?
        /// Source IPs reported since start.
        public let sourcesTotal: Int?
        /// Sources rejected individually in the last accepted report.
        public let lastRejected: Int?
        /// Reasons for rejections with counts.
        public let lastRejectedReasons: [String: Int]?

        enum CodingKeys: String, CodingKey {
            case enabled
            case keySet = "key_set"
            case active
            case sensorID = "sensor_id"
            case lastSuccess = "last_success"
            case lastEnd = "last_end"
            case lastError = "last_error"
            case lastErrorAt = "last_error_at"
            case nextAttempt = "next_attempt"
            case errors
            case sourcesToday = "sources_today"
            case sourcesTotal = "sources_total"
            case lastRejected = "last_rejected"
            case lastRejectedReasons = "last_rejected_reasons"
        }
    }

    /// Status of the log sensor and syslog receiver. Schema `Honeypot64LogStatus`.
    public struct Honeypot64LogStatus: Codable, Hashable, Sendable {
        /// Watched files.
        public let files: [Honeypot64LogFileStatus]?
        /// Syslog receiver; `nil` when off.
        public let syslog: Honeypot64SyslogStatus?
        /// Lines read.
        public let lines: Int?
        /// Hits.
        public let hits: Int?
        /// Events.
        public let events: Int?
    }

    /// State of one watched log file, inline in ``Honeypot64LogStatus``.
    public struct Honeypot64LogFileStatus: Codable, Hashable, Sendable {
        /// Path.
        public let path: String?
        /// Format.
        public let format: String?
        /// Readable.
        public let ok: Bool?
        /// Error text.
        public let error: String?
        /// Lines read.
        public let lines: Int?
        /// Last line time.
        public let last: Date?
    }

    /// State of the syslog receiver, inline in ``Honeypot64LogStatus``.
    public struct Honeypot64SyslogStatus: Codable, Hashable, Sendable {
        /// Port.
        public let port: Int?
        /// UDP listener open.
        public let udp: Bool?
        /// TCP listener open.
        public let tcp: Bool?
        /// Error text.
        public let error: String?
        /// Messages received.
        public let messages: Int?
        /// Messages denied.
        public let denied: Int?
    }
}
