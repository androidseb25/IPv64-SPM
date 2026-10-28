import Foundation

/// Type of a check.
public struct HC2CheckType: IPv64OpenEnum {
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
    public static let push: Self = "push"
    public static let docker: Self = "docker"
}

/// Where a check runs.
public struct HC2Execution: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let online: Self = "online"
    public static let local: Self = "local"
    public static let both: Self = "both"
}

/// IP protocol mode of a check.
public struct HC2IPMode: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let auto: Self = "auto"
    public static let ipv4: Self = "ipv4"
    public static let ipv6: Self = "ipv6"
    public static let both: Self = "both"
}

/// Overall rule when a check has several measuring points.
public struct HC2Policy: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let all: Self = "all"
    public static let any: Self = "any"
    public static let majority: Self = "majority"
}

/// Online measuring location.
public struct HC2Location: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let nuremberg: Self = "nbg"
    public static let falkenstein: Self = "fsn"
}

/// State of a check or measuring point.
public struct HC2CheckState: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let up: Self = "up"
    public static let down: Self = "down"
    public static let degraded: Self = "degraded"
    public static let flapping: Self = "flapping"
    public static let paused: Self = "paused"
    public static let pending: Self = "pending"
}

/// Result of a single measurement.
public struct HC2MeasurementStatus: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let up: Self = "up"
    public static let down: Self = "down"
}

/// Record type of a `dns` check.
public struct HC2DNSRecordType: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let a: Self = "A"
    public static let aaaa: Self = "AAAA"
    public static let cname: Self = "CNAME"
    public static let mx: Self = "MX"
    public static let txt: Self = "TXT"
    public static let ns: Self = "NS"
    public static let srv: Self = "SRV"
    public static let caa: Self = "CAA"
    public static let ptr: Self = "PTR"
    public static let soa: Self = "SOA"
}

/// Resolver of a `dns` check.
public struct HC2DNSResolver: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let system: Self = "system"
    public static let server: Self = "server"
    public static let authoritative: Self = "authoritative"
}

/// Comparison operator of a `json` check rule.
public struct HC2JSONRuleOperator: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let eq: Self = "eq"
    public static let ne: Self = "ne"
    public static let lt: Self = "lt"
    public static let le: Self = "le"
    public static let gt: Self = "gt"
    public static let ge: Self = "ge"
    public static let contains: Self = "contains"
    public static let notContains: Self = "not_contains"
    public static let regex: Self = "regex"
    public static let exists: Self = "exists"
    public static let notExists: Self = "not_exists"
}

/// Time range of check statistics.
public struct HC2StatsRange: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let last24Hours: Self = "24h"
    public static let last7Days: Self = "7d"
    public static let last30Days: Self = "30d"
    public static let lastYear: Self = "1y"
}

/// Aggregation bucket of check statistics.
public struct HC2StatsBucket: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let hour: Self = "hour"
    public static let day: Self = "day"
}

/// Status of a test run.
public struct HC2TestrunStatus: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let pending: Self = "pending"
    public static let running: Self = "running"
    public static let ok: Self = "ok"
    public static let failed: Self = "failed"
    public static let expired: Self = "expired"
}

/// Kind of a check event.
public struct HC2EventKind: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let down: Self = "down"
    public static let up: Self = "up"
    public static let degraded: Self = "degraded"
    public static let degradedEnd: Self = "degraded_end"
    public static let flappingStart: Self = "flapping_start"
    public static let flappingEnd: Self = "flapping_end"
    public static let reminder: Self = "reminder"
}

/// Status of an incident.
public struct HC2IncidentStatus: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let open: Self = "open"
    public static let closed: Self = "closed"
}

/// Type of a notification channel.
public struct HC2ChannelKind: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let ipv64Mail: Self = "ipv64_mail"
    public static let ipv64SMS: Self = "ipv64_sms"
    public static let app: Self = "app"
    public static let telegram: Self = "telegram"
    public static let discord: Self = "discord"
    public static let ntfy: Self = "ntfy"
    public static let gotify: Self = "gotify"
    public static let pushover: Self = "pushover"
    public static let webhook: Self = "webhook"
    public static let smtp: Self = "smtp"
}

/// Where a channel sends from.
public struct HC2ChannelExecution: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let server: Self = "server"
    public static let node: Self = "node"
}

/// Language of channel messages.
public struct HC2ChannelLanguage: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let de: Self = "de"
    public static let en: Self = "en"
}

/// Input kind of a channel type field.
public struct HC2ChannelFieldKind: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let text: Self = "text"
    public static let password: Self = "password"
    public static let url: Self = "url"
    public static let email: Self = "email"
    public static let number: Self = "number"
    public static let select: Self = "select"
    public static let textarea: Self = "textarea"
    public static let bool: Self = "bool"
}

/// Repetition of a maintenance window.
public struct HC2MaintenanceRepeat: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let none: Self = "none"
    public static let daily: Self = "daily"
    public static let weekly: Self = "weekly"
    public static let monthly: Self = "monthly"
}

/// Remote-management level of a node.
public struct HC2RemoteManagement: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let off: Self = "off"
    public static let read: Self = "read"
    public static let full: Self = "full"
}

/// Command that can be sent to a node.
public struct HC2CommandName: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let runCheck: Self = "run_check"
    public static let repair: Self = "repair"
    public static let pause: Self = "pause"
    public static let resume: Self = "resume"
    public static let resolveConflict: Self = "resolve_conflict"
}

/// Which side wins when resolving a sync conflict.
public struct HC2ConflictResolution: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let server: Self = "server"
    public static let local: Self = "local"
}
