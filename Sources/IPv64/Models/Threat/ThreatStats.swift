import Foundation

/// A ranking entry in ``ThreatStats``.
public struct ThreatStatsEntry: Codable, Hashable, Sendable {
    /// The value, e.g. a username.
    public let value: String?
    /// Sum of attempts (30 days).
    public let events: Int?
    /// Distinct reporting accounts (30 days).
    public let accounts: Int?
}

/// Public Honeypot64 overview (cached for at most 10 minutes).
public struct ThreatStats: Codable, Hashable, Sendable {
    /// Cache time (UTC).
    public let generatedAt: Date?
    /// Window of the rankings in days.
    public let windowDays: Int?
    /// Thresholds applied to rankings.
    public let threshold: Threshold?
    /// Sensor counts.
    public let sensors: Sensors?
    /// Attacks in the last 24 hours.
    public let attacks24h: Attacks?
    /// Attacks per day (UTC, 30 days).
    public let timeline: [Day]?
    /// Most attacked ports (7 days, at most 10).
    public let topPorts: [Port]?
    /// Most frequent attack kinds (7 days, at most 10).
    public let topKinds: [Kind]?
    /// List sizes: `v64`, `v64_<sublist>`, `honeypot_passwords`, `honeypot_usernames`, `honeypot_bad_useragents`, `honeypot_attack_paths`.
    public let lists: [String: Int]?
    /// Top 10 per area (30 days, from `threshold.accounts` accounts).
    public let top: Top?
    /// Page with the human-readable statistics.
    public let info: String?
    /// License of the data.
    public let license: String?

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case windowDays = "window_days"
        case threshold, sensors
        case attacks24h = "attacks_24h"
        case timeline
        case topPorts = "top_ports"
        case topKinds = "top_kinds"
        case lists, top, info, license
    }

    /// Thresholds applied to rankings.
    public struct Threshold: Codable, Hashable, Sendable {
        /// Minimum number of reporting accounts for rankings and lists.
        public let accounts: Int?
        /// Accounts whose sensors reported in the last 7 days.
        public let activeAccounts7d: Int?

        enum CodingKeys: String, CodingKey {
            case accounts
            case activeAccounts7d = "active_accounts_7d"
        }
    }

    /// Sensor counts.
    public struct Sensors: Codable, Hashable, Sendable {
        /// Sensors that reported in the last 7 days.
        public let active7d: Int?
        /// Sensors that reported in the last 30 minutes.
        public let online: Int?

        enum CodingKeys: String, CodingKey {
            case active7d = "active_7d"
            case online
        }
    }

    /// Attack totals.
    public struct Attacks: Codable, Hashable, Sendable {
        /// Number of events.
        public let events: Int?
        /// Distinct attacker IPs.
        public let sources: Int?
    }

    /// Attacks of one day.
    public struct Day: Codable, Hashable, Sendable {
        /// Day (`yyyy-MM-dd`, UTC).
        public let day: String?
        /// Number of events.
        public let events: Int?
    }

    /// An attacked port.
    public struct Port: Codable, Hashable, Sendable {
        /// Service, e.g. `ssh`.
        public let service: String?
        /// Port number.
        public let port: Int?
        /// Number of events.
        public let events: Int?
    }

    /// An attack kind.
    public struct Kind: Codable, Hashable, Sendable {
        /// Kind, e.g. `ssh:bruteforce`.
        public let kind: String?
        /// Number of events.
        public let events: Int?
    }

    /// Top-10 rankings.
    public struct Top: Codable, Hashable, Sendable {
        /// Usernames.
        public let usernames: [ThreatStatsEntry]?
        /// Passwords.
        public let passwords: [ThreatStatsEntry]?
        /// Request paths.
        public let paths: [ThreatStatsEntry]?
        /// User agents.
        public let userAgents: [ThreatStatsEntry]?
        /// Tool fingerprints (JA4/HASSH).
        public let fingerprints: [ThreatStatsEntry]?
        /// Countries of origin of listed IPs.
        public let countries: [Country]?

        enum CodingKeys: String, CodingKey {
            case usernames, passwords, paths
            case userAgents = "user_agents"
            case fingerprints, countries
        }
    }

    /// Origin country of listed IPs.
    public struct Country: Codable, Hashable, Sendable {
        /// ISO 3166-1 alpha-2 code.
        public let country: String?
        /// Listed IPs from this country.
        public let ips: Int?
        /// Events of these IPs.
        public let events: Int?
    }
}
