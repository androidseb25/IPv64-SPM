import Foundation

/// A DNS failover policy.
public struct FailoverPolicy: Codable, Hashable, Sendable, Identifiable {
    /// Policy ID (16 characters).
    public let id: String
    /// Name.
    public let name: String?
    /// Status.
    public let status: FailoverPolicyStatus?
    /// The last switch was manual.
    public let manual: Bool?
    /// Switching behavior.
    public let mode: FailoverMode?
    /// Fallback only when all monitors are UP again.
    public let fallbackRequiresAll: Bool?
    /// How monitors are combined.
    public let linking: FailoverLinking?
    /// Notifications are enabled.
    public let notificationsEnabled: Bool?
    /// Integrations for notifications.
    public let integrations: [Int]?
    /// Number of monitors currently counting as DOWN.
    public let monitorsDown: Int?
    /// Last check.
    public let lastCheckAt: Date?
    /// Monitors that trigger the failover.
    public let monitors: [Monitor]?
    /// Protected records and their targets.
    public let rules: [Rule]?

    /// A healthcheck that triggers the failover.
    public struct Monitor: Codable, Hashable, Sendable {
        /// Healthcheck token.
        public let healthcheck: String?
        /// Name.
        public let name: String?
        /// Evaluated inverted (UP counts as DOWN).
        public let negate: Bool?
        /// Current healthcheck status.
        public let healthcheckStatus: HealthcheckStatus?

        enum CodingKeys: String, CodingKey {
            case healthcheck, name, negate
            case healthcheckStatus = "healthcheck_status"
        }
    }

    /// A protected record.
    public struct Rule: Codable, Hashable, Sendable {
        /// Record token of the protected record.
        public let record: String?
        /// Fully qualified name.
        public let fqdn: String?
        /// `A` or `AAAA`.
        public let recordType: RecordType?
        /// State of the rule.
        public let state: FailoverRuleState?
        /// Replacement target.
        public let target: Target?

        /// Replacement target of a rule.
        public struct Target: Codable, Hashable, Sendable {
            /// Kind of target.
            public let kind: FailoverTargetKind?
            /// Replacement IP.
            public let ip: String?
            /// Target record token.
            public let record: String?
            /// `default` or an offline page ID.
            public let offlinePage: String?

            enum CodingKeys: String, CodingKey {
                case kind, ip, record
                case offlinePage = "offline_page"
            }
        }

        enum CodingKeys: String, CodingKey {
            case record, fqdn
            case recordType = "record_type"
            case state, target
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, status, manual, mode
        case fallbackRequiresAll = "fallback_requires_all"
        case linking
        case notificationsEnabled = "notifications_enabled"
        case integrations
        case monitorsDown = "monitors_down"
        case lastCheckAt = "last_check_at"
        case monitors, rules
    }
}

/// Status of a ``FailoverPolicy``.
public struct FailoverPolicyStatus: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// Being set up.
    public static let pending: Self = "pending"
    /// Monitoring.
    public static let active: Self = "active"
    /// Replacement is active.
    public static let failedOver: Self = "failed_over"
    /// Paused.
    public static let paused: Self = "paused"
    /// Switch to the replacement is in progress.
    public static let failoverRequested: Self = "failover_requested"
    /// Switch back is in progress.
    public static let fallbackRequested: Self = "fallback_requested"
}

/// Switching behavior of a ``FailoverPolicy``.
public struct FailoverMode: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// Fail over automatically, fall back manually.
    public static let autoFailover: Self = "auto_failover"
    /// Fail over and fall back automatically.
    public static let autoFailoverAndFallback: Self = "auto_failover_and_fallback"
    /// Switch manually only.
    public static let manual: Self = "manual"
}

/// How the monitors of a policy are combined.
public struct FailoverLinking: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// All monitors must be DOWN.
    public static let and: Self = "and"
    /// One DOWN monitor is enough.
    public static let or: Self = "or"
}

/// State of a failover rule.
public struct FailoverRuleState: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let standby: Self = "standby"
    public static let failedOver: Self = "failed_over"
}

/// Kind of a failover rule target.
public struct FailoverTargetKind: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let ip: Self = "ip"
    public static let record: Self = "record"
    public static let offlinePage: Self = "offline_page"
}

/// Request body to create or update a failover policy. Only non-`nil` fields are sent.
public struct FailoverPolicyInput: Encodable, Hashable, Sendable {
    /// Name.
    public var name: String?
    /// Switching behavior.
    public var mode: FailoverMode?
    /// Fallback only when all monitors are UP again.
    public var fallbackRequiresAll: Bool?
    /// How monitors are combined. Cannot be changed during an active failover.
    public var linking: FailoverLinking?
    /// Enable notifications.
    public var notificationsEnabled: Bool?
    /// Integrations, `0` = account e-mail.
    public var integrations: [Int]?

    public init(
        name: String? = nil,
        mode: FailoverMode? = nil,
        fallbackRequiresAll: Bool? = nil,
        linking: FailoverLinking? = nil,
        notificationsEnabled: Bool? = nil,
        integrations: [Int]? = nil
    ) {
        self.name = name
        self.mode = mode
        self.fallbackRequiresAll = fallbackRequiresAll
        self.linking = linking
        self.notificationsEnabled = notificationsEnabled
        self.integrations = integrations
    }

    enum CodingKeys: String, CodingKey {
        case name, mode
        case fallbackRequiresAll = "fallback_requires_all"
        case linking
        case notificationsEnabled = "notifications_enabled"
        case integrations
    }
}
