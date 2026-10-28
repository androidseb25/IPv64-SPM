import Foundation

extension Node64 {
    /// Kind of token of a DynDNS target. Open enum.
    public struct DynDNSTokenKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Record token.
        public static let record: Self = "record"
        /// Domain token.
        public static let domain: Self = "domain"
    }

    /// How the IPv4 address of a target is determined. Open enum.
    public struct DynDNSIPv4Mode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Detected public IPv4.
        public static let auto: Self = "auto"
        /// Fixed address (`fixed4`).
        public static let fixed: Self = "fixed"
        /// Not updated.
        public static let off: Self = "off"
    }

    /// How the IPv6 address of a target is determined. Open enum.
    public struct DynDNSIPv6Mode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// IPv6 as seen from outside.
        public static let host: Self = "host"
        /// Only the /64 prefix (zone wide).
        public static let prefix: Self = "prefix"
        /// Prefix plus `suffix6` (this record only).
        public static let suffix: Self = "suffix"
        /// Stable address of `iface` (host network).
        public static let iface: Self = "iface"
        /// Fixed address (`fixed6`).
        public static let fixed: Self = "fixed"
        /// Not updated.
        public static let off: Self = "off"
    }

    /// Status of a DynDNS target. Open enum.
    public struct DynDNSTargetStatus: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Not checked yet.
        public static let new: Self = "new"
        /// Up to date.
        public static let ok: Self = "ok"
        /// Up to date; DNS deliberately returns other addresses (CDN or failover).
        public static let cdn: Self = "cdn"
        /// Update pending.
        public static let pending: Self = "pending"
        /// DNS differs.
        public static let dns: Self = "dns"
        /// Last update failed.
        public static let error: Self = "error"
        /// Automatically paused.
        public static let paused: Self = "paused"
        /// Disabled.
        public static let off: Self = "off"
    }

    /// Result of comparing a target with DNS. Open enum.
    public struct DynDNSDNSState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Unknown.
        public static let unknown: Self = "unknown"
        /// Matches.
        public static let ok: Self = "ok"
        /// Differs.
        public static let differs: Self = "differs"
        /// ipv64 deliberately returns other addresses (CDN or failover).
        public static let redirected: Self = "redirected"
    }

    /// Kind of a domain of the ipv64 account. Open enum.
    public struct DynDNSAccountNameKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// DynDNS domain.
        public static let dyndns: Self = "dyndns"
        /// Own domain.
        public static let own: Self = "own"
    }

    /// Result of an immediate update. Open enum.
    public struct DynDNSUpdateOutcome: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Address was sent to ipv64.
        public static let sent: Self = "sent"
        /// No current address known for the modes.
        public static let nothing: Self = "nothing"
    }

    /// Kind of history entries. Open enum.
    public struct DynDNSHistoryType: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Updates sent to ipv64 (default).
        public static let updates: Self = "updates"
        /// IP checks.
        public static let checks: Self = "checks"
    }

    /// IP family filter of the history. Open enum.
    public struct DynDNSIPFamily: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// IPv4.
        public static let v4: Self = "4"
        /// IPv6.
        public static let v6: Self = "6"
    }
}
