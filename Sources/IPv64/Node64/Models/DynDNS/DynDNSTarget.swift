import Foundation

extension Node64 {
    /// DynDNS target (one name at ipv64). Schema `DynDNSTarget`.
    public struct DynDNSTarget: Codable, Hashable, Sendable, Identifiable {
        /// Target ID.
        public let id: Int
        /// Domain at ipv64, e.g. `home.ipv64.net`.
        public let domain: String?
        /// Sub host (prefix); empty means the domain itself.
        public let host: String?
        /// Full name.
        public let fqdn: String?
        /// Record at ipv64 (0 = unknown).
        public let recordID: Int?
        /// Kind of the stored token.
        public let tokenKind: DynDNSTokenKind?
        /// Only the last 4 characters of the token.
        public let tokenHint: String?
        /// IPv4 mode.
        public let mode4: DynDNSIPv4Mode?
        /// Fixed IPv4 address.
        public let fixed4: String?
        /// IPv6 mode.
        public let mode6: DynDNSIPv6Mode?
        /// Fixed IPv6 address.
        public let fixed6: String?
        /// Interface ID for `suffix` mode, e.g. `::1a2b:3c4d:5e6f:7a8b`.
        public let suffix6: String?
        /// Interface for `iface` mode.
        public let iface: String?
        /// Whether the target is enabled.
        public let enabled: Bool?
        /// Reason of an automatic pause (`badauth`, `nohost`, `conflict`, `flapping`, `ignored`); empty = none.
        public let paused: String?
        /// Current status.
        public let status: DynDNSTargetStatus?
        /// Last IPv4 sent.
        public let lastIPv4: String?
        /// Last IPv6 sent.
        public let lastIPv6: String?
        /// Last IPv6 prefix sent.
        public let lastPrefix: String?
        /// Last successful update.
        public let lastOKAt: Date?
        /// Last error text.
        public let lastError: String?
        /// Time of the last error.
        public let lastErrorAt: Date?
        /// Result of comparing with DNS.
        public let dnsState: DynDNSDNSState?

        enum CodingKeys: String, CodingKey {
            case id, domain, host, fqdn
            case recordID = "record_id"
            case tokenKind = "token_kind"
            case tokenHint = "token_hint"
            case mode4, fixed4, mode6, fixed6, suffix6, iface, enabled, paused, status
            case lastIPv4 = "last_ipv4"
            case lastIPv6 = "last_ipv6"
            case lastPrefix = "last_prefix"
            case lastOKAt = "last_ok_at"
            case lastError = "last_error"
            case lastErrorAt = "last_error_at"
            case dnsState = "dns_state"
        }
    }

    /// Request body to create or change a DynDNS target. Schema `DynDNSTargetInput`.
    ///
    /// When changing, an empty `token` keeps the stored token; domain and host cannot be changed.
    public struct DynDNSTargetInput: Encodable, Hashable, Sendable {
        /// Domain at ipv64.
        public var domain: String
        /// Sub host (prefix); empty = domain itself.
        public var host: String?
        /// Kind of token (default `record`).
        public var tokenKind: DynDNSTokenKind?
        /// Record or domain token (24 or 32 characters); empty when changing = unchanged.
        public var token: String
        /// Record at ipv64.
        public var recordID: Int?
        /// IPv4 mode.
        public var mode4: DynDNSIPv4Mode
        /// Fixed IPv4 address (mode `fixed`).
        public var fixed4: String?
        /// IPv6 mode.
        public var mode6: DynDNSIPv6Mode
        /// Fixed IPv6 address (mode `fixed`).
        public var fixed6: String?
        /// Interface ID (mode `suffix`).
        public var suffix6: String?
        /// Interface (mode `iface`).
        public var iface: String?
        /// `true` also lifts an automatic pause.
        public var enabled: Bool?

        public init(
            domain: String,
            host: String? = nil,
            tokenKind: DynDNSTokenKind? = nil,
            token: String,
            recordID: Int? = nil,
            mode4: DynDNSIPv4Mode,
            fixed4: String? = nil,
            mode6: DynDNSIPv6Mode,
            fixed6: String? = nil,
            suffix6: String? = nil,
            iface: String? = nil,
            enabled: Bool? = nil
        ) {
            self.domain = domain
            self.host = host
            self.tokenKind = tokenKind
            self.token = token
            self.recordID = recordID
            self.mode4 = mode4
            self.fixed4 = fixed4
            self.mode6 = mode6
            self.fixed6 = fixed6
            self.suffix6 = suffix6
            self.iface = iface
            self.enabled = enabled
        }

        enum CodingKeys: String, CodingKey {
            case domain, host
            case tokenKind = "token_kind"
            case token
            case recordID = "record_id"
            case mode4, fixed4, mode6, fixed6, suffix6, iface, enabled
        }
    }

    /// Selectable name of the ipv64 account (no tokens). Schema `DynDNSAccountName`.
    public struct DynDNSAccountName: Codable, Hashable, Sendable, Identifiable {
        /// `"<domain>|<host>"`, the key for ``Node64/DynDNS/Targets/createFromAccount(_:)``.
        public let key: String?
        /// Domain.
        public let domain: String?
        /// Host (prefix).
        public let host: String?
        /// Full name.
        public let fqdn: String?
        /// Kind of domain.
        public let kind: DynDNSAccountNameKind?
        /// Existing A records.
        public let a: [String]?
        /// Existing AAAA records.
        public let aaaa: [String]?
        /// Interface ID from the existing AAAA (for mode `suffix`).
        public let suffixOf: String?
        /// Suggested IPv4 mode.
        public let defaultMode4: DynDNSIPv4Mode?
        /// Suggested IPv6 mode.
        public let defaultMode6: DynDNSIPv6Mode?
        /// Already set up as a target.
        public let exists: Bool?
        /// Reason why the name cannot be chosen (CDN, failover).
        public let blocked: String?

        public var id: String { key ?? fqdn ?? "\(domain ?? "")|\(host ?? "")" }

        enum CodingKeys: String, CodingKey {
            case key, domain, host, fqdn, kind, a, aaaa
            case suffixOf = "suffix_of"
            case defaultMode4 = "default_mode4"
            case defaultMode6 = "default_mode6"
            case exists, blocked
        }
    }

    /// One entry of the body of ``Node64/DynDNS/Targets/createFromAccount(_:)``.
    public struct DynDNSAccountSelection: Encodable, Hashable, Sendable {
        /// `key` of a ``DynDNSAccountName``.
        public var key: String
        /// IPv4 mode; `nil` = suggestion.
        public var mode4: DynDNSIPv4Mode?
        /// IPv6 mode; `nil` = suggestion.
        public var mode6: DynDNSIPv6Mode?

        public init(key: String, mode4: DynDNSIPv4Mode? = nil, mode6: DynDNSIPv6Mode? = nil) {
            self.key = key
            self.mode4 = mode4
            self.mode6 = mode6
        }
    }

    /// Settings of the DynDNS module. Schema `DynDNSSettings`.
    ///
    /// Omitted fields keep their value when changing.
    public struct DynDNSSettings: Codable, Hashable, Sendable {
        /// Check interval in minutes (1, 2, 5, 10, 15, 30, 60).
        public var intervalMinutes: Int?
        /// Own check URL for IPv4 (empty = ipv64).
        public var source4: String?
        /// Own check URL for IPv6 (empty = ipv64).
        public var source6: String?
        /// Days to keep IP checks (7, 30, 90, 365).
        public var keepChecksDays: Int?
        /// Days to keep updates (90, 365, 0 = unlimited).
        public var keepUpdatesDays: Int?
        /// Notify on IP change.
        public var notifyIP: Bool?
        /// Notify on failure.
        public var notifyFail: Bool?
        /// Notify when the update limit is reached.
        public var notifyLimit: Bool?

        public init(
            intervalMinutes: Int? = nil,
            source4: String? = nil,
            source6: String? = nil,
            keepChecksDays: Int? = nil,
            keepUpdatesDays: Int? = nil,
            notifyIP: Bool? = nil,
            notifyFail: Bool? = nil,
            notifyLimit: Bool? = nil
        ) {
            self.intervalMinutes = intervalMinutes
            self.source4 = source4
            self.source6 = source6
            self.keepChecksDays = keepChecksDays
            self.keepUpdatesDays = keepUpdatesDays
            self.notifyIP = notifyIP
            self.notifyFail = notifyFail
            self.notifyLimit = notifyLimit
        }

        enum CodingKeys: String, CodingKey {
            case intervalMinutes = "interval_minutes"
            case source4, source6
            case keepChecksDays = "keep_checks_days"
            case keepUpdatesDays = "keep_updates_days"
            case notifyIP = "notify_ip"
            case notifyFail = "notify_fail"
            case notifyLimit = "notify_limit"
        }
    }

    /// Result of ``Node64/DynDNS/status()`` and a finished ``Node64/DynDNS/check()``.
    ///
    /// The spec describes this response only in prose, so all fields are optional best guesses.
    public struct DynDNSStatus: Codable, Hashable, Sendable {
        /// Public IPv4 address.
        public let ipv4: String?
        /// Public IPv6 address.
        public let ipv6: String?
        /// Public IPv6 prefix.
        public let prefix: String?
        /// Hint about the connection type.
        public let connection: DynDNSConnection?
        /// Targets by status (counts or lists, as sent by the node).
        public let targets: JSONValue?
        /// Update limit; only with a central ipv64 API key.
        public let limit: DynDNSLimit?
    }

    /// Connection hint inside ``DynDNSStatus``.
    public struct DynDNSConnection: Codable, Hashable, Sendable {
        /// `cgnat` or `dslite` when the first hops suggest it (not reliably detectable).
        public let suspect: String?
    }

    /// Update limit inside ``DynDNSStatus``.
    public struct DynDNSLimit: Codable, Hashable, Sendable {
        /// Calls used by the account.
        public let used: Int?
        /// Limit of the account (0 = unlimited).
        public let limit: Int?
        /// Calls of this node in the last 24 hours.
        public let own24h: Int?

        enum CodingKeys: String, CodingKey {
            case used, limit
            case own24h = "own_24h"
        }
    }

    /// Result of ``Node64/DynDNS/check()``.
    public enum DynDNSCheckResult: Hashable, Sendable {
        /// The round finished within 45 seconds.
        case completed(DynDNSStatus)
        /// `202`: the round is still running; read ``Node64/DynDNS/status()`` later.
        case running
    }

    /// Result of ``Node64/DynDNS/Targets/updateNow(_:)``.
    public struct DynDNSUpdateResult: Codable, Hashable, Sendable {
        /// `sent` or `nothing`.
        public let result: DynDNSUpdateOutcome?
        /// The target after the update.
        public let target: DynDNSTarget?
    }
}
