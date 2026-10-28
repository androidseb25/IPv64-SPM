import Foundation

extension Node64 {
    /// A healthcheck as the node returns it. Schema `Check`.
    public struct Check: Codable, Hashable, Sendable, Identifiable {
        /// 32-character primary key.
        public let token: String
        /// Name of the check.
        public let name: String?
        /// Check type.
        public let type: CheckType?
        /// Target; depends on the type (URL, host, domain, empty for push).
        public let target: String?
        /// Type-dependent parameters (method, headers, port, expect, `period_seconds`, …).
        public let params: [String: JSONValue]?
        /// Check interval in seconds (5 to 86400 locally, 20 to 86400 online/hybrid).
        public let intervalSeconds: Int?
        /// Interval in seconds while retrying after a failure.
        public let retryIntervalSeconds: Int?
        /// Retries before the check counts as down (0 to 10).
        public let retries: Int?
        /// Connect timeout in seconds.
        public let connectTimeoutSeconds: Double?
        /// Timeout in seconds.
        public let timeoutSeconds: Double?
        /// Inverts the result.
        public let invert: Bool?
        /// Number of equal results needed to change state (1 to 20).
        public let stabilize: Int?
        /// IP version.
        public let ipMode: CheckIPMode?
        /// Tags.
        public let tags: [String]?
        /// Free-form description.
        public let description: String?
        /// The check is paused.
        public let paused: Bool?
        /// Token of the parent check.
        public let parent: String?
        /// Marks the check as critical.
        public let critical: Bool?
        /// Where the check is measured.
        public let execution: CheckExecution?
        /// Overall state with several measuring points.
        public let policy: CheckPolicy?
        /// Online locations (`nbg`, `fsn`).
        public let locations: [String]?
        /// Also notify when partly down.
        public let notifyDegraded: Bool?
        /// Notify when down.
        public let notifyDown: Bool?
        /// Notify when up again.
        public let notifyUp: Bool?
        /// Notification channel IDs; empty means the default channels.
        public let channels: [Int]?
        /// Reminder interval in minutes during an outage (0 = off, up to 1440).
        public let repeatMinutes: Int?
        /// Revision counter (read-only).
        public let revision: Int?
        /// Creation time (read-only).
        public let createdAt: String?
        /// Time of the last change (read-only).
        public let updatedAt: String?
        /// Heartbeat URL of a push check (read-only).
        public let pushURL: String?
        /// Current state (read-only).
        public let state: CheckState?
        /// Free-form group name (at most 100 characters).
        public let group: String?
        /// IDs of the measuring nodes.
        public let nodes: [String]?
        /// Which node owns the check (read-only).
        public let owner: CheckOwner?

        public var id: String { token }

        enum CodingKeys: String, CodingKey {
            case token, name, type, target, params
            case intervalSeconds = "interval_seconds"
            case retryIntervalSeconds = "retry_interval_seconds"
            case retries
            case connectTimeoutSeconds = "connect_timeout_seconds"
            case timeoutSeconds = "timeout_seconds"
            case invert, stabilize
            case ipMode = "ip_mode"
            case tags, description, paused, parent, critical, execution, policy, locations
            case notifyDegraded = "notify_degraded"
            case notifyDown = "notify_down"
            case notifyUp = "notify_up"
            case channels
            case repeatMinutes = "repeat_minutes"
            case revision
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case pushURL = "push_url"
            case state, group, nodes, owner
        }
    }

    /// Writable fields of a check, the body of create and update calls.
    ///
    /// Derived from schema `Check` without the read-only fields (`token`, `revision`,
    /// `created_at`, `updated_at`, `push_url`, `state`, `owner`). `nil` fields are omitted.
    ///
    /// `name`, `type` and `target` are required for create **and** update: `PUT /checks/{token}`
    /// always takes them over. On update, a `nil` ``description`` **clears** the stored description;
    /// all other `nil` fields (`params`, `tags`, `channels`, `locations`, `nodes`, numbers and switches)
    /// keep their stored value.
    public struct CheckInput: Encodable, Hashable, Sendable {
        /// Name of the check.
        public var name: String
        /// Check type.
        public var type: CheckType
        /// Target; required except for push checks (`nil` only for push).
        ///
        /// http/keyword/json: URL; dns: name to query (IP for PTR); icmp/tcp/port/cert: host or IP
        /// (`host:port` is moved into `params.port`); whois: domain, IP/network (CIDR) or AS number.
        public var target: String?
        /// Type-dependent parameters.
        public var params: [String: JSONValue]?
        /// Check interval in seconds.
        public var intervalSeconds: Int?
        /// Interval in seconds while retrying (5 to `intervalSeconds`).
        public var retryIntervalSeconds: Int?
        /// Retries before the check counts as down (0 to 10).
        public var retries: Int?
        /// Connect timeout in seconds.
        public var connectTimeoutSeconds: Double?
        /// Timeout in seconds.
        public var timeoutSeconds: Double?
        /// Inverts the result.
        public var invert: Bool?
        /// Number of equal results needed to change state (1 to 20).
        public var stabilize: Int?
        /// IP version.
        public var ipMode: CheckIPMode?
        /// Tags.
        public var tags: [String]?
        /// Description. On update, `nil` clears the stored description; send the current text to keep it.
        public var description: String?
        /// Create or keep the check paused.
        public var paused: Bool?
        /// Token of the parent check.
        public var parent: String?
        /// Marks the check as critical.
        public var critical: Bool?
        /// Where the check is measured (`online`/`both` need an ipv64 link).
        public var execution: CheckExecution?
        /// Overall state with several measuring points.
        public var policy: CheckPolicy?
        /// Online locations (`nbg`, `fsn`), only with an ipv64 link.
        public var locations: [String]?
        /// Also notify when partly down.
        public var notifyDegraded: Bool?
        /// Notify when down.
        public var notifyDown: Bool?
        /// Notify when up again.
        public var notifyUp: Bool?
        /// Notification channel IDs; empty means the default channels.
        public var channels: [Int]?
        /// Reminder interval in minutes (0 to 1440).
        public var repeatMinutes: Int?
        /// Free-form group name (at most 100 characters).
        public var group: String?
        /// IDs of the measuring nodes (with `local`/`both`, only with an ipv64 link).
        public var nodes: [String]?

        /// Creates a check definition.
        ///
        /// - Parameters:
        ///   - name: Name of the check.
        ///   - type: Check type.
        ///   - target: Target of the check; pass `nil` only for push checks.
        public init(
            name: String,
            type: CheckType,
            target: String?,
            params: [String: JSONValue]? = nil,
            intervalSeconds: Int? = nil,
            retryIntervalSeconds: Int? = nil,
            retries: Int? = nil,
            connectTimeoutSeconds: Double? = nil,
            timeoutSeconds: Double? = nil,
            invert: Bool? = nil,
            stabilize: Int? = nil,
            ipMode: CheckIPMode? = nil,
            tags: [String]? = nil,
            description: String? = nil,
            paused: Bool? = nil,
            parent: String? = nil,
            critical: Bool? = nil,
            execution: CheckExecution? = nil,
            policy: CheckPolicy? = nil,
            locations: [String]? = nil,
            notifyDegraded: Bool? = nil,
            notifyDown: Bool? = nil,
            notifyUp: Bool? = nil,
            channels: [Int]? = nil,
            repeatMinutes: Int? = nil,
            group: String? = nil,
            nodes: [String]? = nil
        ) {
            self.name = name
            self.type = type
            self.target = target
            self.params = params
            self.intervalSeconds = intervalSeconds
            self.retryIntervalSeconds = retryIntervalSeconds
            self.retries = retries
            self.connectTimeoutSeconds = connectTimeoutSeconds
            self.timeoutSeconds = timeoutSeconds
            self.invert = invert
            self.stabilize = stabilize
            self.ipMode = ipMode
            self.tags = tags
            self.description = description
            self.paused = paused
            self.parent = parent
            self.critical = critical
            self.execution = execution
            self.policy = policy
            self.locations = locations
            self.notifyDegraded = notifyDegraded
            self.notifyDown = notifyDown
            self.notifyUp = notifyUp
            self.channels = channels
            self.repeatMinutes = repeatMinutes
            self.group = group
            self.nodes = nodes
        }

        enum CodingKeys: String, CodingKey {
            case name, type, target, params
            case intervalSeconds = "interval_seconds"
            case retryIntervalSeconds = "retry_interval_seconds"
            case retries
            case connectTimeoutSeconds = "connect_timeout_seconds"
            case timeoutSeconds = "timeout_seconds"
            case invert, stabilize
            case ipMode = "ip_mode"
            case tags, description, paused, parent, critical, execution, policy, locations
            case notifyDegraded = "notify_degraded"
            case notifyDown = "notify_down"
            case notifyUp = "notify_up"
            case channels
            case repeatMinutes = "repeat_minutes"
            case group, nodes
        }
    }

    /// Current state of a check. Schema `State`.
    public struct CheckState: Codable, Hashable, Sendable {
        /// State.
        public let state: CheckStateKind?
        /// Since when the state holds.
        public let since: String?
        /// Time of the last measurement.
        public let lastCheckAt: String?
        /// Time of the next measurement.
        public let nextCheckAt: String?
        /// Status of the last measurement.
        public let lastStatus: String?
        /// Latency of the last measurement in milliseconds.
        public let lastLatencyMS: Double?
        /// Reason code of the last measurement.
        public let lastReason: String?
        /// Message of the last measurement.
        public let lastMessage: String?
        /// Consecutive failed measurements.
        public let consecutiveFail: Int?
        /// Consecutive successful measurements.
        public let consecutiveOK: Int?
        /// Time of the last push heartbeat.
        public let lastPushAt: String?
        /// Since when the check is down.
        public let downSince: String?
        /// ID of the open incident.
        public let incidentID: Int?
        /// A maintenance window is active.
        public let maintenance: Bool?

        enum CodingKeys: String, CodingKey {
            case state, since
            case lastCheckAt = "last_check_at"
            case nextCheckAt = "next_check_at"
            case lastStatus = "last_status"
            case lastLatencyMS = "last_latency_ms"
            case lastReason = "last_reason"
            case lastMessage = "last_message"
            case consecutiveFail = "consecutive_fail"
            case consecutiveOK = "consecutive_ok"
            case lastPushAt = "last_push_at"
            case downSince = "down_since"
            case incidentID = "incident_id"
            case maintenance
        }
    }
}
