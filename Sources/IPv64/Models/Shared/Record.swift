import Foundation

/// A DNS record of a domain.
public struct Record: Codable, Hashable, Sendable, Identifiable {
    /// Record ID.
    public let id: Int
    /// ID of the domain the record belongs to.
    public let domainID: Int?
    /// Domain, e.g. `beispiel.ipv64.de`.
    public let domain: String?
    /// Prefix; empty for the domain itself.
    public let prefix: String?
    /// Fully qualified name, e.g. `nas.beispiel.ipv64.de`.
    public let fqdn: String?
    /// Record type.
    public let type: RecordType?
    /// Record content, e.g. `203.0.113.10`.
    public let content: String?
    /// TTL in seconds.
    public let ttl: Int?
    /// Management state of the record.
    public let state: RecordState?
    /// The change is still being propagated to the name servers.
    public let pendingDNS: Bool?
    /// Record token. Stays the same across IP changes and can be used instead of the ID.
    public let token: String?
    /// Last change.
    public let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case domainID = "domain_id"
        case domain, prefix, fqdn, type, content, ttl, state
        case pendingDNS = "pending_dns"
        case token
        case updatedAt = "updated_at"
    }
}

/// DNS record type.
public struct RecordType: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let a: Self = "A"
    public static let aaaa: Self = "AAAA"
    public static let cname: Self = "CNAME"
    public static let mx: Self = "MX"
    public static let txt: Self = "TXT"
    public static let ns: Self = "NS"
    public static let srv: Self = "SRV"
    public static let tlsa: Self = "TLSA"
    public static let caa: Self = "CAA"
}

/// Management state of a ``Record``.
public struct RecordState: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// Active.
    public static let active: Self = "active"
    /// Inactive.
    public static let inactive: Self = "inactive"
    /// Managed by the CDN.
    public static let cdnRecord: Self = "cdn_record"
    /// Routed through the CDN.
    public static let cdnProxied: Self = "cdn_proxied"
    /// Partially routed through the CDN.
    public static let cdnPartial: Self = "cdn_partial"
    /// Temporary replacement created by a DNS failover.
    public static let failoverRecord: Self = "failover_record"
    /// Replaced by a DNS failover.
    public static let failoverReplaced: Self = "failover_replaced"
}
