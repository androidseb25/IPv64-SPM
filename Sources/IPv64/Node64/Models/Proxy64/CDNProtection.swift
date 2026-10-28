import Foundation

extension Node64 {
    /// Action of an access rule.
    public struct CDNAccessAction: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let allow: Self = "allow"
        public static let deny: Self = "deny"
    }

    /// An IP rule of an access list.
    public struct CDNAccessRule: Codable, Hashable, Sendable {
        /// Allow or deny matching addresses.
        public var action: CDNAccessAction?
        /// IP, network or `all`.
        public var cidr: String?

        /// Creates an instance; pass only the fields you want to set.
        public init(action: CDNAccessAction? = nil, cidr: String? = nil) {
            self.action = action
            self.cidr = cidr
        }
    }

    /// A user of an access list (without password).
    public struct CDNAccessListUser: Codable, Hashable, Sendable {
        /// User name.
        public let username: String?
    }

    /// A user of an access list when writing; an empty password keeps the existing one.
    public struct CDNAccessListUserInput: Encodable, Hashable, Sendable {
        /// User name.
        public var username: String?
        /// Empty = keep the existing password.
        public var password: String?

        /// Creates an instance; pass only the fields you want to set.
        public init(username: String? = nil, password: String? = nil) {
            self.username = username
            self.password = password
        }
    }

    /// An access list (without passwords). Schema `CDNAccessList`.
    public struct CDNAccessList: Codable, Hashable, Sendable, Identifiable {
        /// Access list ID.
        public let id: Int
        /// Name of the list.
        public let name: String?
        /// Either a user or an IP rule is enough.
        public let satisfyAny: Bool?
        /// Pass the authorization header on to the target.
        public let passAuth: Bool?
        /// Users of the list.
        public let users: [CDNAccessListUser]?
        /// IP rules of the list.
        public let rules: [CDNAccessRule]?
        /// Creation time.
        public let createdAt: Date?
        /// Time of the last update.
        public let updatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, name
            case satisfyAny = "satisfy_any"
            case passAuth = "pass_auth"
            case users, rules
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    /// Writable fields of an access list. Schema `CDNAccessListInput`.
    public struct CDNAccessListInput: Encodable, Hashable, Sendable {
        /// Name of the list.
        public var name: String?
        /// Either a user or an IP rule is enough.
        public var satisfyAny: Bool?
        /// Pass the authorization header on to the target.
        public var passAuth: Bool?
        /// Replaces the users; `nil` = unchanged.
        public var users: [CDNAccessListUserInput]?
        /// IP rules of the list.
        public var rules: [CDNAccessRule]?

        /// Creates an instance; pass only the fields you want to set.
        public init(
            name: String? = nil,
            satisfyAny: Bool? = nil,
            passAuth: Bool? = nil,
            users: [CDNAccessListUserInput]? = nil,
            rules: [CDNAccessRule]? = nil
        ) {
            self.name = name
            self.satisfyAny = satisfyAny
            self.passAuth = passAuth
            self.users = users
            self.rules = rules
        }

        enum CodingKeys: String, CodingKey {
            case name
            case satisfyAny = "satisfy_any"
            case passAuth = "pass_auth"
            case users, rules
        }
    }

    /// Entry of the access list overview: a list and the hosts using it.
    public struct CDNAccessListEntry: Codable, Hashable, Sendable {
        /// The access list.
        public let accessList: CDNAccessList?
        /// Hosts that use the list.
        public let usedBy: [String]?

        enum CodingKeys: String, CodingKey {
            case accessList = "access_list"
            case usedBy = "used_by"
        }
    }

    /// Edition of a honeypot blocklist.
    public struct CDNBlocklistEdition: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Live version (authorized list token).
        public static let live: Self = "live"
        /// Daily snapshot.
        public static let daily: Self = "daily"
    }

    /// One ipv64 blocklist.
    public struct CDNBlocklist: Codable, Hashable, Sendable {
        /// ID from `https://ipv64.net/blocklists/index.json`, e.g. `all`, `spamhaus_drop`, `tor_exit`.
        public let id: String?
        /// Name of the list.
        public let name: String?
        /// `attack`, `botnet`, `tor`, `cloud` or `honeypot`.
        public let category: String?
        /// Description from ipv64.net (English).
        public let text: String?
        /// License of the list.
        public let license: String?
        /// Project page of the source.
        public let source: String?
        /// Whether the list is enabled.
        public let enabled: Bool?
        /// Number of loaded networks.
        public let entries: Int?
        /// Last checked.
        public let updated: Date?
        /// Last changed.
        public let changed: Date?
        /// Error message of the last load.
        public let error: String?
        /// Honeypot category only: loaded edition.
        public let edition: CDNBlocklistEdition?
        /// The list token was not authorized; the daily snapshot was loaded.
        public let liveDenied: Bool?
        /// Why the live fetch failed; never contains the token.
        public let liveError: String?

        enum CodingKeys: String, CodingKey {
            case id, name, category, text, license, source, enabled, entries, updated, changed, error, edition
            case liveDenied = "live_denied"
            case liveError = "live_error"
        }
    }

    /// Country list loaded for the country filter.
    public struct CDNBlocklistCountry: Codable, Hashable, Sendable {
        /// ISO country code.
        public let code: String?
        /// Number of loaded networks.
        public let entries: Int?
        /// Last checked.
        public let updated: Date?
        /// Error message of the last load.
        public let error: String?
    }

    /// State of the AI bot user-agent list.
    public struct CDNBlocklistAIBots: Codable, Hashable, Sendable {
        /// An enabled host uses the list (it is only loaded then).
        public let needed: Bool?
        /// Number of loaded entries.
        public let entries: Int?
        /// Entries for requests made on behalf of a user.
        public let users: Int?
        /// Last checked.
        public let updated: Date?
        /// Last changed.
        public let changed: Date?
        /// Error message of the last load.
        public let error: String?
        /// Rejected since the start.
        public let blocked: Int?
    }

    /// State of the ipv64 blocklists. Schema `CDNBlocklists`.
    public struct CDNBlocklists: Codable, Hashable, Sendable {
        /// The ipv64 blocklists.
        public let lists: [CDNBlocklist]?
        /// Exceptions: IP addresses or networks.
        public let allow: [String]?
        /// Rejected since the start.
        public let blocked: Int?
        /// At least one list is loaded and enabled.
        public let active: Bool?
        /// Country lists used by the country filter.
        public let countries: [CDNBlocklistCountry]?
        /// Rejected by the country filter since the start.
        public let geoBlocked: Int?
        /// A list token for the live edition is stored (never returned).
        public let tokenSet: Bool?
        /// State of the AI bot user-agent list.
        public let aiBots: CDNBlocklistAIBots?

        enum CodingKeys: String, CodingKey {
            case lists, allow, blocked, active, countries
            case geoBlocked = "geo_blocked"
            case tokenSet = "token_set"
            case aiBots = "ai_bots"
        }
    }

    /// Honeypot64 settings. Schema `CDNHoneypotSettings`.
    public struct CDNHoneypotSettings: Codable, Hashable, Sendable {
        /// Send requests without a matching host to the Honeypot64 web decoy.
        public var decoy: Bool?
        /// Send access metadata to the Honeypot64 log sensor.
        public var access: Bool?
        /// Block IPs reported by the honeypot locally right away.
        public var block: Bool?
        /// Block duration in hours, 1-720 (default 24).
        public var blockHours: Int?

        /// Creates an instance; pass only the fields you want to set.
        public init(decoy: Bool? = nil, access: Bool? = nil, block: Bool? = nil, blockHours: Int? = nil) {
            self.decoy = decoy
            self.access = access
            self.block = block
            self.blockHours = blockHours
        }

        enum CodingKeys: String, CodingKey {
            case decoy, access, block
            case blockHours = "block_hours"
        }
    }

    /// A blocked IP of the honeypot.
    public struct CDNHoneypotBlock: Codable, Hashable, Sendable {
        /// Blocked IP address.
        public let ip: String?
        /// Why the IP was blocked.
        public let reason: String?
        /// Blocked since.
        public let since: Date?
        /// Blocked until.
        public let until: Date?
    }

    /// Honeypot64 settings, blocked IPs and counters. Schema `CDNHoneypotView`.
    public struct CDNHoneypotView: Codable, Hashable, Sendable {
        /// Honeypot64 settings.
        public let settings: CDNHoneypotSettings?
        /// Honeypot64 currently offers a web decoy.
        public let decoyAvailable: Bool?
        /// Honeypot64 currently evaluates accesses.
        public let accessAvailable: Bool?
        /// Currently blocked IPs.
        public let blocks: [CDNHoneypotBlock]?
        /// Rejected since the start.
        public let rejected: Int?
        /// Handed to the decoy since the start.
        public let decoyed: Int?
        /// Handed to the log sensor since the start.
        public let reported: Int?

        enum CodingKeys: String, CodingKey {
            case settings
            case decoyAvailable = "decoy_available"
            case accessAvailable = "access_available"
            case blocks, rejected, decoyed, reported
        }
    }

    /// Overload protection settings per IPv4 address or IPv6 /64; `0` switches a limit off. Schema `CDNLimits`.
    public struct CDNLimits: Codable, Hashable, Sendable {
        /// Whether overload protection is enabled.
        public var enabled: Bool?
        /// Simultaneous connections per IP (default 200).
        public var connsPerIP: Int?
        /// New connections per IP and second, briefly ten times that (default 20).
        public var connRate: Int?
        /// Requests per IP and second, above that 429 (default 50).
        public var reqRate: Int?
        /// Requests in a row (default 500, at least `reqRate`).
        public var reqBurst: Int?
        /// Open connections overall (default 10000).
        public var maxConns: Int?
        /// Simultaneous requests per proxy host to its target; others wait up to 10 s, then 503 (default 200).
        public var targetConns: Int?
        /// Rejections within a minute before an IP is banned (default 300).
        public var banAfter: Int?
        /// Ban duration in minutes, at most 10080 (default 10).
        public var banMinutes: Int?
        /// Never limit private addresses (default true).
        public var exemptLAN: Bool?

        /// Creates an instance; pass only the fields you want to set.
        public init(
            enabled: Bool? = nil,
            connsPerIP: Int? = nil,
            connRate: Int? = nil,
            reqRate: Int? = nil,
            reqBurst: Int? = nil,
            maxConns: Int? = nil,
            targetConns: Int? = nil,
            banAfter: Int? = nil,
            banMinutes: Int? = nil,
            exemptLAN: Bool? = nil
        ) {
            self.enabled = enabled
            self.connsPerIP = connsPerIP
            self.connRate = connRate
            self.reqRate = reqRate
            self.reqBurst = reqBurst
            self.maxConns = maxConns
            self.targetConns = targetConns
            self.banAfter = banAfter
            self.banMinutes = banMinutes
            self.exemptLAN = exemptLAN
        }

        enum CodingKeys: String, CodingKey {
            case enabled
            case connsPerIP = "conns_per_ip"
            case connRate = "conn_rate"
            case reqRate = "req_rate"
            case reqBurst = "req_burst"
            case maxConns = "max_conns"
            case targetConns = "target_conns"
            case banAfter = "ban_after"
            case banMinutes = "ban_minutes"
            case exemptLAN = "exempt_lan"
        }
    }

    /// A banned address.
    public struct CDNLimitBan: Codable, Hashable, Sendable {
        /// IPv4 address or IPv6 /64.
        public let ip: String?
        /// Ban lifted at.
        public let until: Date?
    }

    /// Overload protection: settings, defaults, bans and counters. Schema `CDNLimitsView`.
    public struct CDNLimitsView: Codable, Hashable, Sendable {
        /// Current limits.
        public let limits: CDNLimits?
        /// Default limits.
        public let defaults: CDNLimits?
        /// Currently banned addresses.
        public let bans: [CDNLimitBan]?
        /// Rejected since the start.
        public let rejected: Int?
        /// Currently counted open connections.
        public let conns: Int?
    }
}
