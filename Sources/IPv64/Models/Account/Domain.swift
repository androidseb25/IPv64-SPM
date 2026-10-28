import Foundation

/// A domain of the account.
public struct Domain: Codable, Hashable, Sendable, Identifiable {
    /// Domain ID.
    public let id: Int
    /// Fully qualified name, e.g. `beispiel.ipv64.de`.
    public let name: String?
    /// DynDNS or own domain.
    public let kind: DomainKind?
    /// Zone, e.g. `ipv64.de`.
    public let zone: String?
    /// Wildcard records `*.name` are active.
    public let wildcard: Bool?
    /// Address family ignored on DynDNS updates.
    public let ignore: DomainIgnore?
    /// Fixed IPv6 prefix for interface IDs.
    public let ipv6Prefix: String?
    /// The domain is active.
    public let active: Bool?
    /// Domain update token for `update.php`.
    public let updateToken: String?
    /// Number of DynDNS updates.
    public let updateCount: Int?
    /// Creation time.
    public let createdAt: Date?
    /// Last update.
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, kind, zone, wildcard, ignore
        case ipv6Prefix = "ipv6_prefix"
        case active
        case updateToken = "update_token"
        case updateCount = "update_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// A domain including all its records.
public struct DomainDetail: Codable, Hashable, Sendable, Identifiable {
    /// Domain ID.
    public let id: Int
    /// Fully qualified name, e.g. `beispiel.ipv64.de`.
    public let name: String?
    /// DynDNS or own domain.
    public let kind: DomainKind?
    /// Zone, e.g. `ipv64.de`.
    public let zone: String?
    /// Wildcard records `*.name` are active.
    public let wildcard: Bool?
    /// Address family ignored on DynDNS updates.
    public let ignore: DomainIgnore?
    /// Fixed IPv6 prefix for interface IDs.
    public let ipv6Prefix: String?
    /// The domain is active.
    public let active: Bool?
    /// Domain update token for `update.php`.
    public let updateToken: String?
    /// Number of DynDNS updates.
    public let updateCount: Int?
    /// Creation time.
    public let createdAt: Date?
    /// Last update.
    public let updatedAt: Date?
    /// All records of the domain.
    public let records: [Record]?

    enum CodingKeys: String, CodingKey {
        case id, name, kind, zone, wildcard, ignore
        case ipv6Prefix = "ipv6_prefix"
        case active
        case updateToken = "update_token"
        case updateCount = "update_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case records
    }
}

/// Kind of a ``Domain``.
public struct DomainKind: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// DynDNS domain under one of the IPv64 zones.
    public static let dyndns: Self = "dyndns"
    /// Own domain.
    public static let own: Self = "own"
}

/// Address family that is ignored on DynDNS updates.
public struct DomainIgnore: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// Ignore nothing.
    public static let none: Self = "none"
    /// Ignore IPv4.
    public static let ipv4: Self = "ipv4"
    /// Ignore IPv6.
    public static let ipv6: Self = "ipv6"
}

/// Result of ``IPv64/Domains/updateDynDNS(_:ipv4:ipv6:prefix:)``.
public struct DynDNSResult: Codable, Hashable, Sendable {
    /// Domain.
    public let domain: String?
    /// Prefix.
    public let prefix: String?
    /// At least one record changed.
    public let changed: Bool?
    /// Result per IP address.
    public let results: [Entry]?

    /// Result for one IP address.
    public struct Entry: Codable, Hashable, Sendable {
        /// The IP address.
        public let ip: String?
        /// `A` or `AAAA`.
        public let type: RecordType?
        /// Outcome for this address.
        public let result: DynDNSOutcome?
    }
}

/// Outcome of a DynDNS update for one IP address.
public struct DynDNSOutcome: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let created: Self = "created"
    public static let updated: Self = "updated"
    public static let unchanged: Self = "unchanged"
    public static let ignored: Self = "ignored"
    public static let invalidIP: Self = "invalid_ip"
    public static let cnameConflict: Self = "cname_conflict"
    public static let cdnManaged: Self = "cdn_managed"
}
