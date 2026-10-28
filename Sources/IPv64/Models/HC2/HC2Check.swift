import Foundation

/// A healthchecks 2.0 check.
public struct HC2Check: Codable, Hashable, Sendable, Identifiable {
    /// Current state of a check or measuring point.
    public struct State: Codable, Hashable, Sendable {
        /// State: `up`, `down`, `degraded`, `flapping`, `paused`, `pending`.
        public let state: HC2CheckState?
        /// Since when the state holds.
        public let since: Date?
        /// Time of the last measurement.
        public let lastCheckAt: Date?
        /// Result of the last measurement.
        public let lastStatus: HC2MeasurementStatus?
        /// Latency of the last measurement in milliseconds.
        public let lastLatencyMS: Double?
        /// Reason of the last result.
        public let lastReason: String?
        /// Message of the last result.
        public let lastMessage: String?
        /// Failing since.
        public let downSince: Date?
        /// Time of the last push.
        public let lastPushAt: Date?

        enum CodingKeys: String, CodingKey {
            case state, since
            case lastCheckAt = "last_check_at"
            case lastStatus = "last_status"
            case lastLatencyMS = "last_latency_ms"
            case lastReason = "last_reason"
            case lastMessage = "last_message"
            case downSince = "down_since"
            case lastPushAt = "last_push_at"
        }
    }

    /// Push URLs of a `push` check.
    public struct Push: Codable, Hashable, Sendable {
        /// Push URL at ipv64.
        public let url: String?
        /// Push URL at the hub.
        public let hubURL: String?
        /// Path at the node (`http://<node>/api/push/<token>`).
        public let nodePath: String?

        enum CodingKeys: String, CodingKey {
            case url
            case hubURL = "hub_url"
            case nodePath = "node_path"
        }
    }

    /// A measuring node of a check.
    ///
    /// The API documents the output as `{node_id, name}` objects but the schema as plain ID strings;
    /// both forms decode.
    public struct NodeReference: Codable, Hashable, Sendable {
        /// Node ID.
        public let nodeID: String?
        /// Node name.
        public let name: String?

        enum CodingKeys: String, CodingKey {
            case nodeID = "node_id"
            case name
        }

        public init(from decoder: any Decoder) throws {
            if let id = try? decoder.singleValueContainer().decode(String.self) {
                self.nodeID = id
                self.name = nil
                return
            }
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.nodeID = try container.decodeIfPresent(String.self, forKey: .nodeID)
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
        }
    }

    /// Name.
    public let name: String?

    /// Check type.
    public let type: HC2CheckType?

    /// Target: URL (http/keyword/json), name (dns; IP for PTR), host/IP (icmp), `host` or `host:port` (tcp/port/cert); empty for push.
    public let target: String?

    /// Type-dependent parameters.
    public let params: HC2CheckParams?

    /// Interval in seconds, at least 20.
    public let intervalSeconds: Int?

    /// Retry interval after a failure in seconds, at least 5.
    public let retryIntervalSeconds: Int?

    /// Additional attempts before alerting (0-10).
    public let retries: Int?

    /// Connection timeout in seconds.
    public let connectTimeoutSeconds: Double?

    /// Total timeout in seconds.
    public let timeoutSeconds: Double?

    /// Invert the result.
    public let invert: Bool?

    /// Measurements until a state change (1-20).
    public let stabilize: Int?

    /// IP mode: `auto`, `ipv4`, `ipv6` or `both`.
    public let ipMode: HC2IPMode?

    /// Tags.
    public let tags: [String]?

    /// Group (free-form name).
    public let group: String?

    /// Description.
    public let description: String?

    /// Paused.
    public let paused: Bool?

    /// Token of the parent check (dependency) or empty.
    public let parent: String?

    /// Critical: ignores quiet hours.
    public let critical: Bool?

    /// Where the check runs: `online` (ipv64), `local` (node), `both` (hybrid).
    public let execution: HC2Execution?

    /// Owner node for `local`/`both`; given alone it means a single measuring node.
    public let nodeID: String?

    /// Measuring nodes for `local`/`both`.
    public let nodes: [NodeReference]?

    /// Locations for `online`/`both`.
    public let locations: [HC2Location]?

    /// Overall rule with several measuring points.
    public let policy: HC2Policy?

    /// Also notify when partially degraded.
    public let notifyDegraded: Bool?

    /// Notify on failure.
    public let notifyDown: Bool?

    /// Notify on recovery.
    public let notifyUp: Bool?

    /// Channel IDs; empty = default channels.
    public let channels: [Int]?

    /// Reminder interval while the failure persists, in minutes; 0 = off.
    public let repeatMinutes: Int?

    /// Check token (32 characters).
    public let token: String

    /// Name of the node.
    public let nodeName: String?

    /// Revision.
    public let revision: Int?

    /// Creation time.
    public let createdAt: Date?

    /// Time of the last change.
    public let updatedAt: Date?

    /// Current state.
    public let state: State?

    /// Push URLs, only for type `push`.
    public let push: Push?

    /// Stable identity: the check token.
    public var id: String { token }

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
        case token
        case nodeName = "node_name"
        case revision
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case state
        case push
    }
}
