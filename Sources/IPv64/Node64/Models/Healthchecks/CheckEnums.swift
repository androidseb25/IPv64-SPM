import Foundation

extension Node64 {
    /// Type of a check (`Check.type`).
    public struct CheckType: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let http: Self = "http"
        public static let keyword: Self = "keyword"
        public static let json: Self = "json"
        public static let dns: Self = "dns"
        public static let icmp: Self = "icmp"
        public static let tcp: Self = "tcp"
        public static let port: Self = "port"
        public static let cert: Self = "cert"
        public static let whois: Self = "whois"
        public static let push: Self = "push"
        public static let docker: Self = "docker"
    }

    /// Where a check is measured (`Check.execution`).
    public struct CheckExecution: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// On nodes (see `nodes`).
        public static let local: Self = "local"
        /// Only from the ipv64 locations.
        public static let online: Self = "online"
        /// On nodes and from the ipv64 locations.
        public static let both: Self = "both"
    }

    /// Overall state with several measuring points (`Check.policy`).
    public struct CheckPolicy: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Down only if all measuring points are down.
        public static let all: Self = "all"
        /// Down if one measuring point is down.
        public static let any: Self = "any"
        /// Down if the majority is down.
        public static let majority: Self = "majority"
    }

    /// IP version used by a check (`Check.ip_mode`).
    public struct CheckIPMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let auto: Self = "auto"
        public static let ipv4: Self = "ipv4"
        public static let ipv6: Self = "ipv6"
        public static let both: Self = "both"
    }

    /// Which node owns a check (`Check.owner`).
    public struct CheckOwner: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// This node owns the check.
        public static let thisNode: Self = "self"
        /// Another node of the account owns it (still editable here).
        public static let other: Self = "other"
        /// The check exists only at ipv64.
        public static let online: Self = "online"
    }

    /// Current state of a check (`State.state`).
    public struct CheckStateKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let pending: Self = "pending"
        public static let up: Self = "up"
        public static let degraded: Self = "degraded"
        public static let down: Self = "down"
        public static let stabilizing: Self = "stabilizing"
        public static let flapping: Self = "flapping"
        public static let dependent: Self = "dependent"
        public static let paused: Self = "paused"
    }

    /// Result of a single measurement (`Measurement.status`).
    public struct CheckMeasurementStatus: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let up: Self = "up"
        public static let down: Self = "down"
    }

    /// Time range of ``Node64/HC/Checks/stats(_:range:)``.
    public struct CheckStatsRange: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let lastHour: Self = "1h"
        public static let last24Hours: Self = "24h"
        public static let last7Days: Self = "7d"
        public static let last30Days: Self = "30d"
        public static let lastYear: Self = "1y"
    }

    /// Time range of ``Node64/HC/Checks/chart(_:range:)``.
    public struct CheckChartRange: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let lastHour: Self = "1h"
        public static let last6Hours: Self = "6h"
        public static let last24Hours: Self = "24h"
        public static let last7Days: Self = "7d"
        public static let last30Days: Self = "30d"
        public static let lastYear: Self = "1y"
    }

    /// Aggregation of chart points (`CheckChart.bucket`).
    public struct CheckChartBucket: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Single measurements (1h to 24h).
        public static let raw: Self = "raw"
        /// Hourly values (7d, 30d).
        public static let hour: Self = "hour"
        /// Daily values (1y).
        public static let day: Self = "day"
    }

    /// Action of ``Node64/HC/Checks/bulk(_:tokens:tag:)``.
    public struct CheckBulkAction: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let pause: Self = "pause"
        public static let resume: Self = "resume"
        public static let run: Self = "run"
        public static let delete: Self = "delete"
        /// Adds a tag (needs `tag`).
        public static let tag: Self = "tag"
        /// Removes a tag (needs `tag`).
        public static let untag: Self = "untag"
    }

    /// Outcome of an online test run (``CheckOnlineTestResult/status``).
    public struct CheckOnlineTestStatus: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let ok: Self = "ok"
        public static let failed: Self = "failed"
        public static let expired: Self = "expired"
    }

    /// Repetition of a maintenance window.
    public struct MaintenanceRepeat: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let none: Self = "none"
        public static let daily: Self = "daily"
        public static let weekly: Self = "weekly"
        public static let monthly: Self = "monthly"
    }

    /// Action of ``Node64/HC/OnlineChecks/perform(_:action:)`` (`POST /online-checks/{token}/{action}`).
    public struct OnlineCheckAction: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let pause: Self = "pause"
        public static let resume: Self = "resume"
        public static let run: Self = "run"
    }

    /// Status reported by a push heartbeat (query `status`).
    public struct PushStatus: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let up: Self = "up"
        public static let down: Self = "down"
    }
}
