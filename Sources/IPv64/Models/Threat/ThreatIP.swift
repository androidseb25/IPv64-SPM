import Foundation

/// Information about an IP address on the v64 Blocklist.
public struct ThreatIP: Codable, Hashable, Sendable {
    /// Normalized address.
    public let ip: String?
    /// Address family (4 or 6).
    public let family: Int?
    /// On the v64 Blocklist (releases are already deducted).
    public let listed: Bool?
    /// Listing status.
    public let status: Status?
    /// Confidence score 0 to 100 (only when listed).
    public let score: Int?
    /// Sub-lists (`ssh`, `web`, `mail`, `rdp`, `scanner`, `research`).
    public let lists: [ThreatList]?
    /// Attack kinds, e.g. `ssh:bruteforce`.
    public let kinds: [String]?
    /// Attacked ports reported by at least 2 accounts (at most 10).
    public let ports: [Port]?
    /// First sighting (`yyyy-MM-dd`, UTC).
    public let firstSeen: String?
    /// Last sighting (`yyyy-MM-dd`, UTC).
    public let lastSeen: String?
    /// Number of distinct reporting accounts.
    public let accounts: Int?
    /// Country (ISO 3166-1), if known.
    public let country: String?
    /// Autonomous system number, if known.
    public let asn: Int?
    /// Release (delisting) state.
    public let release: Release?
    /// Page with explanation and release request.
    public let details: String?

    enum CodingKeys: String, CodingKey {
        case ip, family, listed, status, score, lists, kinds, ports
        case firstSeen = "first_seen"
        case lastSeen = "last_seen"
        case accounts, country, asn, release, details
    }

    /// Listing status of an IP.
    public struct Status: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// On the blocklist.
        public static let listed: Self = "listed"
        /// Not on the blocklist.
        public static let notListed: Self = "not_listed"
        /// Temporarily released after a request.
        public static let released: Self = "released"
        /// On the allowlist.
        public static let allowlisted: Self = "allowlisted"
    }

    /// An attacked port.
    public struct Port: Codable, Hashable, Sendable {
        /// Service, e.g. `ssh`.
        public let service: String?
        /// Port number.
        public let port: Int?
    }

    /// Release state of an IP.
    public struct Release: Codable, Hashable, Sendable {
        /// State of the release request.
        public let status: Status?
        /// Release is valid until (UTC); `nil` means permanent or no release.
        public let protectedUntil: Date?

        enum CodingKeys: String, CodingKey {
            case status
            case protectedUntil = "protected_until"
        }

        /// State of a release request.
        public struct Status: IPv64OpenEnum {
            public let rawValue: String
            public init(rawValue: String) { self.rawValue = rawValue }

            public static let none: Self = "none"
            public static let inReview: Self = "in_review"
            public static let released: Self = "released"
            public static let allowlisted: Self = "allowlisted"
            public static let rejected: Self = "rejected"
        }
    }
}

/// A v64 Blocklist sub-list.
public struct ThreatList: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let ssh: Self = "ssh"
    public static let web: Self = "web"
    public static let mail: Self = "mail"
    public static let rdp: Self = "rdp"
    public static let scanner: Self = "scanner"
    public static let research: Self = "research"
}
