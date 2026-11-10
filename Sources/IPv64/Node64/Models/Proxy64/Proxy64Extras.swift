import Foundation

extension Node64 {
    /// Docker sync settings of PROXY64 (`settings` of ``Proxy64Docker``).
    public struct Proxy64DockerSettings: Codable, Hashable, Sendable {
        /// Create proxy hosts from Docker labels (`node64.proxy.*`).
        public let enabled: Bool?
        /// Also read `traefik.*` labels (default on).
        public let traefik: Bool?
        /// Docker API of this node (`unix://` or `tcp://` to a docker-socket-proxy, no `ssh://`); `""` = default.
        public let dockerHost: String?
        /// Certificate for new Docker hosts: `""` (none), `auto`, `ipv64`, `http` or `dns:<account>`.
        public let certificate: String?

        enum CodingKeys: String, CodingKey {
            case enabled, traefik
            case dockerHost = "docker_host"
            case certificate
        }
    }

    /// State of the Docker sync. Schema of `GET /cdn64/docker`.
    public struct Proxy64Docker: Codable, Hashable, Sendable {
        /// Sync is switched on.
        public let enabled: Bool?
        /// The Docker API is reachable.
        public let connected: Bool?
        /// Docker API as used.
        public let host: String?
        /// Error of the last sync.
        public let error: String?
        /// Time of the last sync.
        public let synced: Date?
        /// Containers with `node64.proxy.*` or `traefik.*` labels (free-form objects, the spec documents no fields).
        public let containers: [JSONValue]?
        /// Current settings.
        public let settings: Proxy64DockerSettings?
    }

    /// CDN64 servers and connections per server. Fields come from ipv64.
    public struct Proxy64Servers: Codable, Hashable, Sendable {
        /// Assigned servers.
        public let count: Int?
        /// Chosen number (`0` = maximum, or all including future ones).
        public let choice: Int?
        /// Maximum number.
        public let max: Int?
        /// All servers, including future ones.
        public let all: Bool?
        /// Total number of servers.
        public let total: Int?
        /// The number is selectable (class).
        public let selectable: Bool?
        /// Assigned servers.
        public let assigned: [String]?
        /// Servers currently in DNS.
        public let active: [String]?
        /// Connections per server.
        public let sessions: Int?
        /// Maximum connections per server.
        public let sessionsMax: Int?
        /// Failover: failed server to replacement.
        public let replaced: [String: String]?
        /// Selectable numbers, `0` = all (including future ones); empty = fixed.
        public let options: [Int]?
        /// Selectable connections per server; empty = fixed.
        public let sessionOptions: [Int]?

        enum CodingKeys: String, CodingKey {
            case count, choice, max, all, total, selectable, assigned, active, sessions
            case sessionsMax = "sessions_max"
            case replaced, options
            case sessionOptions = "session_options"
        }
    }

    /// JA4 handling of CDN64 (`off`, `count`, `block`).
    public struct CDNJA4Mode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Not set (empty string, only in statistics).
        public static let unset: Self = ""
        public static let off: Self = "off"
        /// Only count (start phase).
        public static let count: Self = "count"
        public static let block: Self = "block"
    }

    /// One name in ``Proxy64HostProtection``.
    public struct Proxy64HostProtectionName: Codable, Hashable, Sendable {
        /// ID of the name at ipv64.
        public let id: Int?
        /// Full name.
        public let fqdn: String?
        /// Pattern WAF is on.
        public let waf: Bool?
        /// JA4 mode as a string.
        public let ja4: CDNJA4Mode?
    }

    /// CDN64 protection (WAF, JA4) of the names of a host.
    public struct Proxy64HostProtection: Codable, Hashable, Sendable {
        /// Pattern WAF is on.
        public let waf: Bool?
        /// JA4 mode.
        public let ja4: CDNJA4Mode?
        /// Per name.
        public let names: [Proxy64HostProtectionName]?
    }

    /// Result of ``Node64/Proxy64/Hosts/addLocalDNS(_:ipv4:ipv6:)``.
    public struct Proxy64LocalDNSResult: Codable, Hashable, Sendable {
        /// Number of records added.
        public let added: Int?
        /// `"name type"` entries that already existed.
        public let skipped: [String]?
        /// Names left out (wildcards, main domains).
        public let excluded: [String]?
        /// IPv4 address used.
        public let ipv4: String?
        /// IPv6 address used.
        public let ipv6: String?
    }

    /// Sums of ``Proxy64ProtectionStats``.
    public struct Proxy64ProtectionTotals: Codable, Hashable, Sendable {
        /// Blocked by blocklists.
        public let blockedList: Int?
        /// Blocked by access lists.
        public let blockedACL: Int?
        /// Blocked by flood protection.
        public let blockedFlood: Int?
        /// Blocked by limits.
        public let blockedLimit: Int?
        /// Blocked by the WAF.
        public let blockedWAF: Int?
        /// Blocked by JA4.
        public let blockedJA4: Int?
        /// JA4 hits.
        public let ja4Hits: Int?
        /// Blocked IP addresses.
        public let blockedIPs: Int?
        /// Connections.
        public let conns: Int?
        /// IPv4 connections.
        public let connsV4: Int?

        enum CodingKeys: String, CodingKey {
            case blockedList = "blocked_list"
            case blockedACL = "blocked_acl"
            case blockedFlood = "blocked_flood"
            case blockedLimit = "blocked_limit"
            case blockedWAF = "blocked_waf"
            case blockedJA4 = "blocked_ja4"
            case ja4Hits = "ja4_hits"
            case blockedIPs = "blocked_ips"
            case conns
            case connsV4 = "conns_v4"
        }
    }

    /// A JA4 fingerprint with its hits.
    public struct Proxy64JA4Hit: Codable, Hashable, Sendable {
        /// JA4 fingerprint.
        public let ja4: String?
        /// Number of hits.
        public let hits: Int?
    }

    /// Protection statistics of one name.
    public struct Proxy64ProtectionHost: Codable, Hashable, Sendable {
        /// ID of the name at ipv64.
        public let id: Int?
        /// Full name.
        public let fqdn: String?
        /// Mode.
        public let mode: Int?
        /// Host ID on this node; missing = none.
        public let hostID: Int?
        /// Blocked requests.
        public let blocked: Int?
        /// Overload rejections.
        public let overload: Int?
        /// Pattern WAF is on.
        public let waf: Bool?
        /// JA4 mode.
        public let ja4: CDNJA4Mode?

        enum CodingKeys: String, CodingKey {
            case id, fqdn, mode
            case hostID = "host_id"
            case blocked, overload, waf, ja4
        }
    }

    /// What the CDN64 servers blocked for the names of the account. Schema of `GET /cdn64/protection`.
    public struct Proxy64ProtectionStats: Codable, Hashable, Sendable {
        /// Number of days covered.
        public let days: Int?
        /// Global JA4 phase: `count` = start phase (count only), `block`.
        public let ja4Global: CDNJA4Mode?
        /// Sums.
        public let totals: Proxy64ProtectionTotals?
        /// Per day (free-form objects, the spec documents no fields).
        public let daily: [JSONValue]?
        /// Top JA4 fingerprints.
        public let ja4Top: [Proxy64JA4Hit]?
        /// Per name, with WAF/JA4.
        public let hosts: [Proxy64ProtectionHost]?

        enum CodingKeys: String, CodingKey {
            case days
            case ja4Global = "ja4_global"
            case totals, daily
            case ja4Top = "ja4_top"
            case hosts
        }
    }

    /// Which automatic block ``Node64/Proxy64/release(ip:from:)`` lifts.
    public struct Proxy64ReleaseSource: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Both (empty string).
        public static let both: Self = ""
        /// Block of the honeypot.
        public static let honeypot: Self = "honeypot"
        /// Ban of the overload protection.
        public static let ban: Self = "ban"
    }
}
