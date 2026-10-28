import Foundation

/// A DNS64 client (personal resolver configuration).
///
/// Changes are applied asynchronously (`202 Accepted`). A change is complete once
/// ``state`` is `ready`; resolver addresses and ``clientID`` are available then.
public struct DNS64Client: Codable, Hashable, Sendable, Identifiable {
    /// Client ID (token).
    public let id: String
    /// Name.
    public let name: String?
    /// Short identifier used in the resolver addresses.
    public let clientID: String?
    /// State of the client.
    public let state: DNS64ClientState?
    /// Filtering enabled.
    public let blockingEnabled: Bool?
    /// Active blocklists.
    public let blocklists: [DNS64Blocklist]?
    /// Resolver servers.
    public let servers: [Server]?
    /// Total number of queries.
    public let queriesTotal: Int?
    /// Number of blocked queries.
    public let queriesBlocked: Int?
    /// Creation time.
    public let createdAt: Date?
    /// Own allow and block list (detail view only).
    public let rules: [Rule]?
    /// Source addresses for the shared resolver IPs (detail view only).
    public let sources: [Source]?

    /// A resolver server of the client.
    public struct Server: Codable, Hashable, Sendable {
        /// Location, e.g. `Falkenstein`.
        public let location: String?
        /// Hostname.
        public let hostname: String?
        /// DNS over HTTPS URL.
        public let doh: String?
        /// DNS over TLS hostname.
        public let dot: String?
        /// DNS over QUIC hostname.
        public let doq: String?
        /// Personal IPv6 address of the resolver.
        public let ipv6: String?
        /// Shared IPv4 address (matched via source addresses).
        public let ipv4Shared: String?
        /// Shared IPv6 address.
        public let ipv6Shared: String?
        /// DNS stamps (detail view only).
        public let stamps: Stamps?

        /// DNS stamps.
        public struct Stamps: Codable, Hashable, Sendable {
            /// DNS over HTTPS stamp.
            public let doh: String?
            /// DNS over TLS stamp.
            public let dot: String?
            /// DNS over QUIC stamp.
            public let doq: String?
        }

        enum CodingKeys: String, CodingKey {
            case location, hostname, doh, dot, doq, ipv6
            case ipv4Shared = "ipv4_shared"
            case ipv6Shared = "ipv6_shared"
            case stamps
        }
    }

    /// An allow or block rule for a domain.
    public struct Rule: Codable, Hashable, Sendable, Identifiable {
        /// Rule ID.
        public let id: Int
        /// Domain.
        public let domain: String?
        /// Action.
        public let action: DNS64RuleAction?
        /// State of the rule.
        public let state: DNS64ClientState?
    }

    /// A source address that assigns requests to the client.
    public struct Source: Codable, Hashable, Sendable, Identifiable {
        /// Numeric ID for kind `ip`, record token for kind `record`.
        public let id: String
        /// Kind of source.
        public let kind: DNS64SourceKind?
        /// Address.
        public let address: String?
        /// Name, only for kind `record`.
        public let fqdn: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case clientID = "client_id"
        case state
        case blockingEnabled = "blocking_enabled"
        case blocklists, servers
        case queriesTotal = "queries_total"
        case queriesBlocked = "queries_blocked"
        case createdAt = "created_at"
        case rules, sources
    }
}

/// Result of ``IPv64/DNS64/delete(_:)``.
public struct DNS64DeleteResult: Codable, Hashable, Sendable, Identifiable {
    /// Client ID.
    public let id: String
    /// State, normally ``DNS64ClientState/deleting``.
    public let state: DNS64ClientState?
}

/// State of a DNS64 client or rule.
public struct DNS64ClientState: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// All changes are applied.
    public static let ready: Self = "ready"
    /// A change is being applied in the background.
    public static let applying: Self = "applying"
    /// The client is being deleted.
    public static let deleting: Self = "deleting"
}

/// Blocklist of a DNS64 client. `adult` and `threats` are not part of the Free plan.
public struct DNS64Blocklist: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let ads: Self = "ads"
    public static let adult: Self = "adult"
    public static let threats: Self = "threats"
}

/// Action of a DNS64 rule.
public struct DNS64RuleAction: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let allow: Self = "allow"
    public static let block: Self = "block"
}

/// Kind of a DNS64 source address.
public struct DNS64SourceKind: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// A fixed IP address.
    public static let ip: Self = "ip"
    /// An own A/AAAA record whose DynDNS address is followed.
    public static let record: Self = "record"
}
