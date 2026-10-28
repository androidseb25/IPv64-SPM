import Foundation

/// A healthcheck.
public struct Healthcheck: Codable, Hashable, Sendable, Identifiable {
    /// Healthcheck token, identifies the check.
    public let token: String
    /// Name.
    public let name: String?
    /// Kind of check.
    public let type: HealthcheckType?
    /// Current status.
    public let status: HealthcheckStatus?
    /// Notification settings.
    public let notify: Notify?
    /// Creation time.
    public let createdAt: Date?
    /// Last ping or last check.
    public let lastSeenAt: Date?
    /// Last alarm.
    public let lastAlarmAt: Date?
    /// Number of pings.
    public let pingsTotal: Int?
    /// Consecutive failures.
    public let failedInRow: Int?
    /// Push settings. Only for type `push`.
    public let push: Push?
    /// Settings of active checks (icmp, tcp, http, keyword). `nil` until configured.
    public let check: Check?

    public var id: String { token }

    /// Notification settings of a healthcheck.
    public struct Notify: Codable, Hashable, Sendable {
        /// Notify on DOWN.
        public let onDown: Bool?
        /// Notify on UP.
        public let onUp: Bool?
        /// IDs of the integrations, `0` = account e-mail.
        public let integrations: [Int]?

        enum CodingKeys: String, CodingKey {
            case onDown = "on_down"
            case onUp = "on_up"
            case integrations
        }
    }

    /// Push settings of a healthcheck.
    public struct Push: Codable, Hashable, Sendable {
        /// Your system pings this URL.
        public let url: String?
        /// Expected interval between pings in seconds.
        public let periodSeconds: Int?
        /// Grace time in seconds.
        public let graceSeconds: Int?
        /// Latest time for the next ping.
        public let expectedBy: Date?

        enum CodingKeys: String, CodingKey {
            case url
            case periodSeconds = "period_seconds"
            case graceSeconds = "grace_seconds"
            case expectedBy = "expected_by"
        }
    }

    /// Settings of an active healthcheck.
    public struct Check: Codable, Hashable, Sendable {
        /// Target for icmp and tcp.
        public let target: String?
        /// Prefer IPv4.
        public let preferIPv4: Bool?
        /// Port for tcp.
        public let port: Int?
        /// URL for http and keyword.
        public let url: String?
        /// Verify the TLS certificate.
        public let verifyTLS: Bool?
        /// Search term for keyword.
        public let keyword: String?
        /// Check interval in seconds.
        public let intervalSeconds: Int?
        /// Interval after a failure in seconds.
        public let retryIntervalSeconds: Int?
        /// Failures until an alarm is raised.
        public let failuresBeforeAlarm: Int?
        /// Next check.
        public let nextCheckAt: Date?

        enum CodingKeys: String, CodingKey {
            case target
            case preferIPv4 = "prefer_ipv4"
            case port, url
            case verifyTLS = "verify_tls"
            case keyword
            case intervalSeconds = "interval_seconds"
            case retryIntervalSeconds = "retry_interval_seconds"
            case failuresBeforeAlarm = "failures_before_alarm"
            case nextCheckAt = "next_check_at"
        }
    }

    enum CodingKeys: String, CodingKey {
        case token, name, type, status, notify
        case createdAt = "created_at"
        case lastSeenAt = "last_seen_at"
        case lastAlarmAt = "last_alarm_at"
        case pingsTotal = "pings_total"
        case failedInRow = "failed_in_row"
        case push, check
    }
}

/// A healthcheck including its most recent events.
public struct HealthcheckDetail: Codable, Hashable, Sendable, Identifiable {
    /// Healthcheck token, identifies the check.
    public let token: String
    /// Name.
    public let name: String?
    /// Kind of check.
    public let type: HealthcheckType?
    /// Current status.
    public let status: HealthcheckStatus?
    /// Notification settings.
    public let notify: Healthcheck.Notify?
    /// Creation time.
    public let createdAt: Date?
    /// Last ping or last check.
    public let lastSeenAt: Date?
    /// Last alarm.
    public let lastAlarmAt: Date?
    /// Number of pings.
    public let pingsTotal: Int?
    /// Consecutive failures.
    public let failedInRow: Int?
    /// Push settings. Only for type `push`.
    public let push: Healthcheck.Push?
    /// Settings of active checks (icmp, tcp, http, keyword). `nil` until configured.
    public let check: Healthcheck.Check?
    /// The last 20 events.
    public let recent: [HealthcheckEvent]?

    public var id: String { token }

    enum CodingKeys: String, CodingKey {
        case token, name, type, status, notify
        case createdAt = "created_at"
        case lastSeenAt = "last_seen_at"
        case lastAlarmAt = "last_alarm_at"
        case pingsTotal = "pings_total"
        case failedInRow = "failed_in_row"
        case push, check, recent
    }
}

/// Request body to create or update a healthcheck.
///
/// When updating, only non-`nil` fields are sent. Changing ``type`` resets the check settings.
public struct HealthcheckInput: Encodable, Hashable, Sendable {
    /// Name.
    public var name: String?
    /// Kind of check. The web UI names `health`, `ping` and `web` are accepted as well.
    public var type: HealthcheckType?
    /// Integrations for notifications, `0` = account e-mail.
    public var integrations: [Int]?
    /// Notify on DOWN.
    public var notifyOnDown: Bool?
    /// Notify on UP.
    public var notifyOnUp: Bool?
    /// push: expected interval between pings in seconds (whole minutes, hours or days, min. 60).
    public var periodSeconds: Int?
    /// push: grace time after the period in seconds (whole minutes, hours or days, min. 60).
    public var graceSeconds: Int?
    /// icmp and tcp: host name or IP.
    public var target: String?
    /// icmp and tcp: prefer IPv4.
    public var preferIPv4: Bool?
    /// tcp: port (1 to 65535).
    public var port: Int?
    /// http and keyword: URL.
    public var url: String?
    /// http and keyword: verify the certificate.
    public var verifyTLS: Bool?
    /// keyword: text that must appear on the page.
    public var keyword: String?
    /// Active checks: check interval in seconds (1 to 86400, free plan min. 120).
    public var intervalSeconds: Int?
    /// Active checks: interval after a failure in seconds (10 to 86400).
    public var retryIntervalSeconds: Int?
    /// Active checks: failures until an alarm (1 to 60).
    public var failuresBeforeAlarm: Int?

    public init(
        name: String? = nil,
        type: HealthcheckType? = nil,
        integrations: [Int]? = nil,
        notifyOnDown: Bool? = nil,
        notifyOnUp: Bool? = nil,
        periodSeconds: Int? = nil,
        graceSeconds: Int? = nil,
        target: String? = nil,
        preferIPv4: Bool? = nil,
        port: Int? = nil,
        url: String? = nil,
        verifyTLS: Bool? = nil,
        keyword: String? = nil,
        intervalSeconds: Int? = nil,
        retryIntervalSeconds: Int? = nil,
        failuresBeforeAlarm: Int? = nil
    ) {
        self.name = name
        self.type = type
        self.integrations = integrations
        self.notifyOnDown = notifyOnDown
        self.notifyOnUp = notifyOnUp
        self.periodSeconds = periodSeconds
        self.graceSeconds = graceSeconds
        self.target = target
        self.preferIPv4 = preferIPv4
        self.port = port
        self.url = url
        self.verifyTLS = verifyTLS
        self.keyword = keyword
        self.intervalSeconds = intervalSeconds
        self.retryIntervalSeconds = retryIntervalSeconds
        self.failuresBeforeAlarm = failuresBeforeAlarm
    }

    enum CodingKeys: String, CodingKey {
        case name, type, integrations
        case notifyOnDown = "notify_on_down"
        case notifyOnUp = "notify_on_up"
        case periodSeconds = "period_seconds"
        case graceSeconds = "grace_seconds"
        case target
        case preferIPv4 = "prefer_ipv4"
        case port, url
        case verifyTLS = "verify_tls"
        case keyword
        case intervalSeconds = "interval_seconds"
        case retryIntervalSeconds = "retry_interval_seconds"
        case failuresBeforeAlarm = "failures_before_alarm"
    }
}

/// Result of ``IPv64/Healthchecks/sendTestNotification(_:)``.
public struct HealthcheckTestNotificationResult: Codable, Hashable, Sendable {
    /// The notification was sent.
    public let sent: Bool?
}
