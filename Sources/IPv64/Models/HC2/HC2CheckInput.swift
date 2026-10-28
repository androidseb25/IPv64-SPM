import Foundation

/// Request body for creating or updating a check. When updating, only the fields provided are changed.
public struct HC2CheckInput: Encodable, Hashable, Sendable {
    /// Name.
    public var name: String

    /// Check type.
    public var type: HC2CheckType

    /// Target: URL (http/keyword/json), name (dns; IP for PTR), host/IP (icmp), `host` or `host:port` (tcp/port/cert); empty for push.
    public var target: String?

    /// Type-dependent parameters.
    public var params: HC2CheckParams?

    /// Interval in seconds, at least 20.
    public var intervalSeconds: Int?

    /// Retry interval after a failure in seconds, at least 5.
    public var retryIntervalSeconds: Int?

    /// Additional attempts before alerting (0-10).
    public var retries: Int?

    /// Connection timeout in seconds.
    public var connectTimeoutSeconds: Double?

    /// Total timeout in seconds.
    public var timeoutSeconds: Double?

    /// Invert the result.
    public var invert: Bool?

    /// Measurements until a state change (1-20).
    public var stabilize: Int?

    /// IP mode: `auto`, `ipv4`, `ipv6` or `both`.
    public var ipMode: HC2IPMode?

    /// Tags.
    public var tags: [String]?

    /// Group (free-form name).
    public var group: String?

    /// Description.
    public var description: String?

    /// Paused.
    public var paused: Bool?

    /// Token of the parent check (dependency) or empty.
    public var parent: String?

    /// Critical: ignores quiet hours.
    public var critical: Bool?

    /// Where the check runs: `online` (ipv64), `local` (node), `both` (hybrid).
    public var execution: HC2Execution?

    /// Owner node for `local`/`both`; given alone it means a single measuring node.
    public var nodeID: String?

    /// Measuring node IDs for `local`/`both`; several allowed, Docker/Push exactly one.
    public var nodes: [String]?

    /// Locations for `online`/`both` (count depends on the account class).
    public var locations: [HC2Location]?

    /// Overall rule with several measuring points.
    public var policy: HC2Policy?

    /// Also notify when partially degraded.
    public var notifyDegraded: Bool?

    /// Notify on failure.
    public var notifyDown: Bool?

    /// Notify on recovery.
    public var notifyUp: Bool?

    /// Channel IDs; empty = default channels.
    public var channels: [Int]?

    /// Reminder interval while the failure persists, in minutes; 0 = off.
    public var repeatMinutes: Int?

    /// Creates a check body; only non-`nil` optional fields are sent.
    public init(
        name: String,
        type: HC2CheckType,
        target: String? = nil,
        params: HC2CheckParams? = nil,
        intervalSeconds: Int? = nil,
        retryIntervalSeconds: Int? = nil,
        retries: Int? = nil,
        connectTimeoutSeconds: Double? = nil,
        timeoutSeconds: Double? = nil,
        invert: Bool? = nil,
        stabilize: Int? = nil,
        ipMode: HC2IPMode? = nil,
        tags: [String]? = nil,
        group: String? = nil,
        description: String? = nil,
        paused: Bool? = nil,
        parent: String? = nil,
        critical: Bool? = nil,
        execution: HC2Execution? = nil,
        nodeID: String? = nil,
        nodes: [String]? = nil,
        locations: [HC2Location]? = nil,
        policy: HC2Policy? = nil,
        notifyDegraded: Bool? = nil,
        notifyDown: Bool? = nil,
        notifyUp: Bool? = nil,
        channels: [Int]? = nil,
        repeatMinutes: Int? = nil
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
        self.group = group
        self.description = description
        self.paused = paused
        self.parent = parent
        self.critical = critical
        self.execution = execution
        self.nodeID = nodeID
        self.nodes = nodes
        self.locations = locations
        self.policy = policy
        self.notifyDegraded = notifyDegraded
        self.notifyDown = notifyDown
        self.notifyUp = notifyUp
        self.channels = channels
        self.repeatMinutes = repeatMinutes
    }

    enum CodingKeys: String, CodingKey {
        case name
        case type
        case target
        case params
        case intervalSeconds = "interval_seconds"
        case retryIntervalSeconds = "retry_interval_seconds"
        case retries
        case connectTimeoutSeconds = "connect_timeout_seconds"
        case timeoutSeconds = "timeout_seconds"
        case invert
        case stabilize
        case ipMode = "ip_mode"
        case tags
        case group
        case description
        case paused
        case parent
        case critical
        case execution
        case nodeID = "node_id"
        case nodes
        case locations
        case policy
        case notifyDegraded = "notify_degraded"
        case notifyDown = "notify_down"
        case notifyUp = "notify_up"
        case channels
        case repeatMinutes = "repeat_minutes"
    }
}
