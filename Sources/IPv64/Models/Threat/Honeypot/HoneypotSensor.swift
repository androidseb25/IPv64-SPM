import Foundation

/// A Honeypot64 sensor of the account. The sensor's IP is never returned.
public struct HoneypotSensor: Codable, Hashable, Sendable, Identifiable {
    /// Sensor ID (UUID string, fixed per installation).
    public let id: String
    /// Sensor software version.
    public let version: String?
    /// Sensor profile.
    public let profile: String?
    /// Operating mode.
    public let mode: String?
    /// First report.
    public let firstSeen: Date?
    /// Last report.
    public let lastSeen: Date?
    /// Reported within the last 30 minutes.
    public let online: Bool?
    /// Number of reports.
    public let reports: Int?
    /// The sensor is disabled.
    public let disabled: Bool?
    /// Distinct source IPs in 24 hours.
    public let sources24h: Int?
    /// Distinct source IPs in 7 days.
    public let sources7d: Int?
    /// Events in 24 hours.
    public let events24h: Int?
    /// Events in 7 days.
    public let events7d: Int?

    enum CodingKeys: String, CodingKey {
        case id, version, profile, mode
        case firstSeen = "first_seen"
        case lastSeen = "last_seen"
        case online, reports, disabled
        case sources24h = "sources_24h"
        case sources7d = "sources_7d"
        case events24h = "events_24h"
        case events7d = "events_7d"
    }
}

/// Contribution of the account to Honeypot64.
public struct HoneypotStats: Codable, Hashable, Sendable {
    /// Number of sensors.
    public let sensors: Int?
    /// Number of sensors online.
    public let sensorsOnline: Int?
    /// At least one sensor reported within the last 7 days.
    public let contributor: Bool?
    /// Time of the last report.
    public let lastReport: Date?
    /// Events in 24 hours.
    public let events24h: Int?
    /// Events in 7 days.
    public let events7d: Int?
    /// Distinct source IPs in 24 hours.
    public let sources24h: Int?
    /// Distinct source IPs in 7 days.
    public let sources7d: Int?
    /// Top attack kinds (7 days).
    public let topKinds: [Kind]?
    /// Top ports (7 days).
    public let topPorts: [Port]?
    /// Events per day (UTC, 7 days).
    public let timeline: [Day]?

    enum CodingKeys: String, CodingKey {
        case sensors
        case sensorsOnline = "sensors_online"
        case contributor
        case lastReport = "last_report"
        case events24h = "events_24h"
        case events7d = "events_7d"
        case sources24h = "sources_24h"
        case sources7d = "sources_7d"
        case topKinds = "top_kinds"
        case topPorts = "top_ports"
        case timeline
    }

    /// Statistics of one attack kind.
    public struct Kind: Codable, Hashable, Sendable {
        /// Attack kind, e.g. `ssh:bruteforce`.
        public let kind: String?
        /// Number of events.
        public let events: Int?
        /// Number of distinct sources.
        public let sources: Int?
    }

    /// Statistics of one port.
    public struct Port: Codable, Hashable, Sendable {
        /// Service, e.g. `ssh`.
        public let service: String?
        /// Port number.
        public let port: Int?
        /// Number of events.
        public let events: Int?
        /// Number of distinct sources.
        public let sources: Int?
    }

    /// Events of one day.
    public struct Day: Codable, Hashable, Sendable {
        /// Day (`yyyy-MM-dd`, UTC).
        public let day: String?
        /// Number of events.
        public let events: Int?
    }
}
