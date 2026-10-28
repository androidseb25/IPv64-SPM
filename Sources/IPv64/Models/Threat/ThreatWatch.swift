import Foundation

/// Early-warning configuration: limits, networks and automatically watched DynDNS IPs.
public struct ThreatWatch: Codable, Hashable, Sendable {
    /// Limits of the account class.
    public let limits: Limits?
    /// Registered networks.
    public let networks: [ThreatWatchNetwork]?
    /// Automatically watched DynDNS IPs (count as verified).
    public let dyndns: [DynDNS]?

    /// Limits of the early warning.
    public struct Limits: Codable, Hashable, Sendable {
        /// Networks per account (Standard 3, otherwise 50).
        public let max: Int?
        /// Largest allowed IPv4 network (`/16`).
        public let minPrefixV4: Int?
        /// Largest allowed IPv6 network (`/32`).
        public let minPrefixV6: Int?

        enum CodingKeys: String, CodingKey {
            case max
            case minPrefixV4 = "min_prefix_v4"
            case minPrefixV6 = "min_prefix_v6"
        }
    }

    /// An automatically watched DynDNS IP.
    public struct DynDNS: Codable, Hashable, Sendable {
        /// IP address.
        public let ip: String?
        /// Domain.
        public let domain: String?
    }
}

/// A watched network.
public struct ThreatWatchNetwork: Codable, Hashable, Sendable, Identifiable {
    /// Network ID.
    public let id: Int
    /// Normalized network (without host bits), e.g. `203.0.113.0/24`.
    public let cidr: String?
    /// Label.
    public let label: String?
    /// Ownership verified: every sighting alerts, otherwise only listed IPs do.
    public let verified: Bool?
    /// Creation time.
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, cidr, label, verified
        case createdAt = "created_at"
    }
}

/// An early-warning alert.
public struct ThreatWatchAlert: Codable, Hashable, Sendable, Identifiable {
    /// Alert ID.
    public let id: Int
    /// The attacking IP.
    public let ip: String?
    /// Network, or the IP as `/32` or `/128` for DynDNS.
    public let cidr: String?
    /// Network ID; `nil` for DynDNS alerts.
    public let networkID: Int?
    /// Origin of the alert.
    public let source: Source?
    /// Network label, or the domain for DynDNS alerts.
    public let label: String?
    /// On the v64 Blocklist.
    public let listed: Bool?
    /// Confidence score 0 to 100.
    public let score: Int?
    /// Attack kinds.
    public let kinds: [String]?
    /// First sighting (`yyyy-MM-dd`, UTC).
    public let firstSeen: String?
    /// Last sighting (`yyyy-MM-dd`, UTC).
    public let lastSeen: String?
    /// Creation time.
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, ip, cidr
        case networkID = "network_id"
        case source, label, listed, score, kinds
        case firstSeen = "first_seen"
        case lastSeen = "last_seen"
        case createdAt = "created_at"
    }

    /// Origin of an alert.
    public struct Source: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// A registered network.
        public static let network: Self = "network"
        /// A DynDNS IP of the account.
        public static let dyndns: Self = "dyndns"
    }
}

/// A batch of early-warning alerts.
public struct ThreatWatchAlerts: Codable, Hashable, Sendable {
    /// Alerts, oldest first (at most 100).
    public let alerts: [ThreatWatchAlert]?
    /// Opaque cursor; pass it unchanged as `since` of the next call.
    public let next: String?
}
