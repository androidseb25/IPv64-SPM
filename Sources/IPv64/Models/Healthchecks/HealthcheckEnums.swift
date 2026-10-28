import Foundation

/// Kind of a healthcheck.
public struct HealthcheckType: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// Passive check: your system pings the push URL regularly.
    public static let push: Self = "push"
    /// Active ICMP ping.
    public static let icmp: Self = "icmp"
    /// Active TCP port check.
    public static let tcp: Self = "tcp"
    /// Active HTTP check.
    public static let http: Self = "http"
    /// Active HTTP check that looks for a keyword on the page.
    public static let keyword: Self = "keyword"
}

/// Status of a healthcheck or healthcheck event.
public struct HealthcheckStatus: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let new: Self = "new"
    public static let up: Self = "up"
    public static let paused: Self = "paused"
    public static let warning: Self = "warning"
    public static let down: Self = "down"
    public static let stabilizing: Self = "stabilizing"
}

/// Time range of ``HealthcheckStats``.
public struct HealthcheckStatsRange: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let oneHour: Self = "1h"
    public static let twentyFourHours: Self = "24h"
    public static let sevenDays: Self = "7d"
    public static let thirtyDays: Self = "30d"
}

/// Status of an ``Incident``.
public struct IncidentStatus: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let open: Self = "open"
    public static let closed: Self = "closed"
}
