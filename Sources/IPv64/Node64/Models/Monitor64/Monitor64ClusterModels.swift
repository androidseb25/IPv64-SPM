import Foundation

extension Node64 {
    /// Role of this node for a host in the cluster (schema `Monitor64ClusterHost`, `role`).
    public struct Monitor64ClusterHostRole: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// This node reports the host.
        public static let report: Self = "report"
        /// This node only measures.
        public static let measure: Self = "measure"
        /// This node does nothing for the host.
        public static let idle: Self = "idle"
    }

    /// Why a host is orphaned (schema `Monitor64Orphan`, `reason`).
    public struct Monitor64OrphanReason: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// The responsible node is gone.
        public static let nodeGone: Self = "node_gone"
        /// No node qualifies.
        public static let noCandidate: Self = "no_candidate"
    }

    /// Kind of an entry in the overview's "recent" list.
    public struct Monitor64OverviewKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `ok`
        public static let ok: Self = "ok"
        /// Problem resolved.
        public static let resolved: Self = "resolved"
        /// Maintenance started.
        public static let maint: Self = "maint"
        /// Maintenance ended.
        public static let maintEnd: Self = "maint_end"
    }

    /// State of a service (schema `Monitor64OverviewProblem`, `state`).
    public struct Monitor64OverviewProblemState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `ok`
        public static let ok: Self = "ok"
        /// `warn`
        public static let warn: Self = "warn"
        /// `crit`
        public static let crit: Self = "crit"
        /// `unknown`
        public static let unknown: Self = "unknown"
    }

    /// Time range of ``Monitor64/series(host:series:range:offset:from:to:points:)``.
    public struct Monitor64SeriesRange: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `6h`
        public static let sixHours: Self = "6h"
        /// `24h`
        public static let day: Self = "24h"
        /// `7d`
        public static let week: Self = "7d"
        /// `30d`
        public static let month: Self = "30d"
        /// `1y`
        public static let year: Self = "1y"
    }

    /// A node of the cluster. Schema `Monitor64ClusterNode`.
    public struct Monitor64ClusterNode: Codable, Hashable, Sendable {
        /// ID of the node.
        public let id: String?
        /// Name of the node.
        public let name: String?
        /// This is the node you talk to.
        public let isSelf: Bool?
        /// The node is online.
        public let online: Bool?
        /// Reachable for 5 minutes (may become responsible).
        public let stable: Bool?

        enum CodingKeys: String, CodingKey {
            case id, name, online, stable
            case isSelf = "self"
        }
    }

    /// Responsibility for a host, seen from this node. Schema `Monitor64ClusterHost`.
    public struct Monitor64ClusterHost: Codable, Hashable, Sendable {
        /// UID of the host.
        public let uid: String
        /// Name of the host.
        public let name: String?
        /// ID of the responsible node.
        public let owner: String?
        /// Name of the responsible node.
        public let ownerName: String?
        /// ID of the preferred node.
        public let preferred: String?
        /// IDs of the backup nodes.
        public let backups: [String]?
        /// View of this node.
        public let role: Monitor64ClusterHostRole?
        /// The responsible node is reachable.
        public let reachable: Bool?

        enum CodingKeys: String, CodingKey {
            case uid, name, owner, preferred, backups, role, reachable
            case ownerName = "owner_name"
        }
    }

    /// Which node monitors a host. Schema `Monitor64ClusterRef`.
    public struct Monitor64ClusterRef: Codable, Hashable, Sendable {
        /// ID of the node.
        public let node: String?
        /// Name of the node.
        public let name: String?
        /// This node queries the host.
        public let here: Bool?
        /// The monitoring node reports.
        public let reporting: Bool?
        /// The monitoring node is reachable.
        public let reachable: Bool?
        /// `owner_unreachable`, `no_data` or `measure_only`.
        public let note: String?
        /// State of the other node.
        public let at: Date?
    }

    /// Responsibility details of one host (`GET /monitor64/cluster/hosts/{uid}`). Schema `Monitor64ClusterHostInfo`.
    public struct Monitor64ClusterHostInfo: Codable, Hashable, Sendable {
        /// Cluster mode is active.
        public let active: Bool?
        /// ID of this node.
        public let isSelf: String?
        /// A majority of nodes is connected.
        public let majority: Bool?
        /// Members of the cluster.
        public let nodes: [Monitor64ClusterNode]?
        /// Responsibility for the host.
        public let host: Monitor64ClusterHost?
        /// Which node monitors the host.
        public let ref: Monitor64ClusterRef?
        /// Latest takeovers and handbacks (at most 20).
        public let events: [Monitor64Event]?

        enum CodingKeys: String, CodingKey {
            case active, majority, nodes, host, ref, events
            case isSelf = "self"
        }
    }

    /// Request of ``Monitor64/Cluster-swift.struct/updateHost(_:_:)``.
    public struct Monitor64ClusterHostInput: Codable, Hashable, Sendable {
        /// ID of the preferred node; empty = this node.
        public var preferredNode: String?
        /// IDs of the backup nodes, at most 8 (duplicates and the preferred node are dropped).
        public var backupNodes: [String]?

        /// Creates an input; `nil` fields are not sent.
        public init(preferredNode: String? = nil, backupNodes: [String]? = nil) {
            self.preferredNode = preferredNode
            self.backupNodes = backupNodes
        }

        enum CodingKeys: String, CodingKey {
            case preferredNode = "preferred_node"
            case backupNodes = "backup_nodes"
        }
    }

    /// Result of ``Monitor64/Cluster-swift.struct/updateHost(_:_:)`` (inline schema).
    public struct Monitor64ClusterHostUpdate: Codable, Hashable, Sendable {
        /// UID of the host.
        public let uid: String?
        /// ID of the preferred node.
        public let preferredNode: String?
        /// IDs of the backup nodes.
        public let backupNodes: [String]?

        enum CodingKeys: String, CodingKey {
            case uid
            case preferredNode = "preferred_node"
            case backupNodes = "backup_nodes"
        }
    }

    /// Keys of this node, without the private key. Schema `Monitor64ClusterKeys`.
    public struct Monitor64ClusterKeys: Codable, Hashable, Sendable {
        /// A not yet converted access.
        public struct Pending: Codable, Hashable, Sendable {
            /// UID of the access.
            public let accessUID: String?
            /// UID of the host.
            public let hostUID: String?
            /// Name of the host.
            public let hostName: String?
            /// Access type.
            public let type: String?
            /// Number of attempts.
            public let tries: Int?
            /// Time of the last attempt.
            public let lastTry: Date?
            /// Last error.
            public let error: String?
            /// SSH: add the line by hand, then confirm.
            public let manual: Bool?

            enum CodingKeys: String, CodingKey {
                case type, tries, error, manual
                case accessUID = "access_uid"
                case hostUID = "host_uid"
                case hostName = "host_name"
                case lastTry = "last_try"
            }
        }

        /// Fingerprint of the current key.
        public let fingerprint: String?
        /// Line for `authorized_keys` or the install command (public key).
        public let authorizedKey: String?
        /// Shared cluster key.
        public let cluster: Bool?
        /// Creation time of the key.
        public let at: Date?
        /// Fingerprints of old keys that are still offered.
        public let oldKeys: [String]?
        /// Accesses not yet converted.
        public let pending: [Pending]?
        /// A conversion runs in the background; query again.
        public let running: Bool?

        enum CodingKeys: String, CodingKey {
            case fingerprint, cluster, at, pending, running
            case authorizedKey = "authorized_key"
            case oldKeys = "old_keys"
        }
    }

    /// Cluster overview (`GET /monitor64/cluster`). Schema `Monitor64Cluster`.
    public struct Monitor64Cluster: Codable, Hashable, Sendable {
        /// Cluster mode is active.
        public let active: Bool?
        /// ID of this node.
        public let isSelf: String?
        /// A majority of nodes is connected.
        public let majority: Bool?
        /// Number of nodes.
        public let total: Int?
        /// Number of connected nodes.
        public let connected: Int?
        /// Nodes.
        public let nodes: [Monitor64ClusterNode]?
        /// Responsibility per host (view of this node).
        public let hosts: [Monitor64ClusterHost]?
        /// Keys of this node.
        public let key: Monitor64ClusterKeys?

        enum CodingKeys: String, CodingKey {
            case active, majority, total, connected, nodes, hosts, key
            case isSelf = "self"
        }
    }

    /// An orphaned host that no node monitors. Schema `Monitor64Orphan`.
    public struct Monitor64Orphan: Codable, Hashable, Sendable {
        /// UID of the host.
        public let uid: String?
        /// Name of the host.
        public let name: String?
        /// Address of the host.
        public let address: String?
        /// Why it is orphaned.
        public let reason: Monitor64OrphanReason?
        /// Previously responsible node.
        public let node: String?
        /// Name of that node.
        public let nodeName: String?

        enum CodingKeys: String, CodingKey {
            case uid, name, address, reason, node
            case nodeName = "node_name"
        }
    }

    /// Result of ``Monitor64/Cluster-swift.struct/orphans()`` (inline schema).
    public struct Monitor64Orphans: Codable, Hashable, Sendable {
        /// Cluster mode is active.
        public let active: Bool?
        /// ID of this node.
        public let isSelf: String?
        /// Orphaned hosts.
        public let orphans: [Monitor64Orphan]?

        enum CodingKeys: String, CodingKey {
            case active, orphans
            case isSelf = "self"
        }
    }

    /// Request of assigning or removing orphaned hosts: `uids` or `all` is required. Schema `Monitor64OrphanInput`.
    public struct Monitor64OrphanInput: Codable, Hashable, Sendable {
        /// UIDs of the hosts.
        public var uids: [String]?
        /// All orphaned hosts.
        public var all: Bool?

        /// Creates an input; set `uids` or `all`.
        public init(uids: [String]? = nil, all: Bool? = nil) {
            self.uids = uids
            self.all = all
        }
    }

    /// Result of assigning or removing orphans. Schema `Monitor64OrphanResult`.
    public struct Monitor64OrphanResult: Codable, Hashable, Sendable {
        /// Number of handled hosts.
        public let done: Int?
        /// Remaining orphaned hosts.
        public let orphans: [Monitor64Orphan]?
    }

    /// Reachability test of a host from all nodes. Schema `Monitor64ClusterReach`.
    public struct Monitor64ClusterReach: Codable, Hashable, Sendable {
        /// Result of one node.
        public struct NodeResult: Codable, Hashable, Sendable {
            /// Result of one access.
            public struct AccessResult: Codable, Hashable, Sendable {
                /// UID of the access.
                public let access: String?
                /// Access type.
                public let type: String?
                /// The access answers.
                public let ok: Bool?
                /// Error message.
                public let error: String?
                /// Response time in milliseconds.
                public let ms: Int?
                /// Push mode: only the agent's own node tests.
                public let skip: Bool?
            }

            /// ID of the node.
            public let node: String?
            /// Name of the node.
            public let name: String?
            /// This is the node you talk to.
            public let isSelf: Bool?
            /// All tested accesses answer.
            public let ok: Bool?
            /// Error message.
            public let error: String?
            /// Tested accesses.
            public let accesses: [AccessResult]?

            enum CodingKeys: String, CodingKey {
                case node, name, ok, error, accesses
                case isSelf = "self"
            }
        }

        /// Results per node, this node first.
        public let nodes: [NodeResult]?
    }

    /// Which node monitors which host (`GET /monitor64/cluster/views`). Schema `Monitor64ClusterViews`.
    public struct Monitor64ClusterViews: Codable, Hashable, Sendable {
        /// Cluster mode is active.
        public let active: Bool?
        /// ID of this node.
        public let isSelf: String?
        /// Name of this node.
        public let selfName: String?
        /// Host UID to the monitoring node.
        public let refs: [String: Monitor64ClusterRef]?
        /// Orphaned hosts (only without `host`).
        public let orphans: [Monitor64Orphan]?

        enum CodingKeys: String, CodingKey {
            case active, refs, orphans
            case isSelf = "self"
            case selfName = "self_name"
        }
    }

    /// Problem in the overview. Schema `Monitor64OverviewProblem`.
    public struct Monitor64OverviewProblem: Codable, Hashable, Sendable {
        /// UID of the host.
        public let hostUID: String?
        /// Name of the host.
        public let host: String?
        /// Service key; empty = host unreachable.
        public let key: String?
        /// Name of the service.
        public let name: String?
        /// State.
        public let state: Monitor64OverviewProblemState?
        /// Detail text.
        public let detail: String?
        /// Since when.
        public let since: Date?
        /// Acknowledged.
        public let acked: Bool?
        /// In maintenance.
        public let maint: Bool?
        /// Caused by an unreachable host.
        public let unreach: Bool?

        enum CodingKeys: String, CodingKey {
            case host, key, name, state, detail, since, acked, maint, unreach
            case hostUID = "host_uid"
        }
    }

    /// Overview (`GET /monitor64/overview`). Schema `Monitor64Overview`.
    public struct Monitor64Overview: Codable, Hashable, Sendable {
        /// Services per state.
        public struct Counts: Codable, Hashable, Sendable {
            /// Services in state ok.
            public let ok: Int?
            /// Services in state warn.
            public let warn: Int?
            /// Services in state crit.
            public let crit: Int?
            /// Services in state unknown.
            public let unknown: Int?
        }

        /// A recently resolved problem or maintenance.
        public struct Recent: Codable, Hashable, Sendable {
            /// Kind of entry.
            public let kind: Monitor64OverviewKind?
            /// UID of the host.
            public let hostUID: String?
            /// Name of the host.
            public let host: String?
            /// Name of the service.
            public let name: String?
            /// Text.
            public let text: String?
            /// Who did it.
            public let by: Monitor64Actor?
            /// Time.
            public let at: Date?

            enum CodingKeys: String, CodingKey {
                case kind, host, name, text, by, at
                case hostUID = "host_uid"
            }
        }

        /// Services per state.
        public let counts: Counts?
        /// All hosts with their current state.
        public let hosts: [Monitor64OverviewHost]?
        /// Open problems.
        public let problems: [Monitor64OverviewProblem]?
        /// Recently resolved problems and maintenance (at most 8).
        public let recent: [Recent]?
        /// Host groups.
        public let groups: [String]?
        /// Number of unreachable hosts.
        public let unreachable: Int?
        /// Number of services.
        public let services: Int?
        /// Open, unacknowledged problems.
        public let openUnacked: Int?
        /// The module runs (scheduler active).
        public let running: Bool?

        enum CodingKeys: String, CodingKey {
            case counts, hosts, problems, recent, groups, unreachable, services, running
            case openUnacked = "open_unacked"
        }
    }

    /// Chart data of a host (`GET /monitor64/series`). Schema `Monitor64Series`.
    public struct Monitor64Series: Codable, Hashable, Sendable {
        /// One data point.
        public struct Point: Codable, Hashable, Sendable {
            /// Unix seconds.
            public let t: Int?
            /// Minimum.
            public let min: Double?
            /// Average.
            public let avg: Double?
            /// Maximum.
            public let max: Double?
            /// Width of this point in seconds.
            public let s: Int?
        }

        /// One series as requested.
        public struct Entry: Codable, Hashable, Sendable {
            /// `service|metric` as requested.
            public let s: String?
            /// Resolution: `raw`, `5m`, `1h` (empty without data).
            public let res: String?
            /// Width of the points in seconds (0 = single raw values).
            public let step: Int?
            /// Points.
            public let points: [Point]?
        }

        /// Piece delivered by another node.
        public struct ClusterPart: Codable, Hashable, Sendable {
            /// ID of the node.
            public let node: String?
            /// Name of the node.
            public let name: String?
            /// The piece arrived.
            public let ok: Bool?
            /// Node not reachable: gap.
            public let missing: Bool?
        }

        /// Start, Unix seconds.
        public let from: Int?
        /// End, Unix seconds.
        public let to: Int?
        /// The requested series.
        public let series: [Entry]?
        /// Pieces of other nodes (cluster).
        public let cluster: [ClusterPart]?
    }

    /// Technical state of the module. Schema `Monitor64Status`.
    public struct Monitor64Status: Codable, Hashable, Sendable {
        /// State of the scheduler.
        public struct Scheduler: Codable, Hashable, Sendable {
            /// Number of jobs.
            public let jobs: Int?
            /// Running jobs.
            public let running: Int?
            /// Workers.
            public let workers: Int?
            /// Total runs.
            public let runs: Int?
            /// Late runs.
            public let late: Int?
        }

        /// Version of the module.
        public let version: String?
        /// Uptime as Go duration, e.g. `3h2m1s`.
        public let uptime: String?
        /// Scheduler state.
        public let scheduler: Scheduler?
        /// Size of the history in MB.
        public let historyMB: Double?
        /// Hosts of the load generator.
        public let loadgenHosts: Int?
        /// Points per second of the load generator.
        public let loadgenPointsPerSec: Double?
        /// Heap in MB.
        public let heapMB: Double?
        /// Number of goroutines.
        public let goroutines: Int?

        enum CodingKeys: String, CodingKey {
            case version, uptime, scheduler, goroutines
            case historyMB = "history_mb"
            case loadgenHosts = "loadgen_hosts"
            case loadgenPointsPerSec = "loadgen_points_per_sec"
            case heapMB = "heap_mb"
        }
    }

    /// Settings (`GET /monitor64/settings`). Schema `Monitor64Settings`.
    public struct Monitor64Settings: Codable, Hashable, Sendable {
        /// State of the push listener.
        public struct Push: Codable, Hashable, Sendable {
            /// Counters of the listener (keys `Tokens`, `Pending`, `Parked`).
            public struct Stats: Codable, Hashable, Sendable {
                /// Number of tokens.
                public let tokens: Int?
                /// Pending agents.
                public let pending: Int?
                /// Parked agents.
                public let parked: Int?

                enum CodingKeys: String, CodingKey {
                    case tokens = "Tokens"
                    case pending = "Pending"
                    case parked = "Parked"
                }
            }

            /// Listening addresses.
            public let listening: [String]?
            /// Counters.
            public let stats: Stats?
        }

        /// Default interval of new hosts in seconds.
        public let interval: Int?
        /// Concurrent queries.
        public let workers: Int?
        /// Hours the raw history is kept.
        public let retentionRawHours: Int?
        /// Days the 5-minute history is kept.
        public let retention5mDays: Int?
        /// Days the 1-hour history is kept.
        public let retention1hDays: Int?
        /// Number of hosts.
        public let hosts: Int?
        /// Number of services.
        public let services: Int?
        /// Technical state.
        public let status: Monitor64Status?
        /// Port of the agent.
        public let port: Int?
        /// Public key of the node (line for `authorized_keys`).
        public let publicKey: String?
        /// Fingerprint of the key.
        public let fingerprint: String?
        /// Port of the trap receiver.
        public let trapPort: Int?
        /// State of the trap receiver.
        public let traps: Monitor64TrapStatus?
        /// Port for agents in push mode.
        public let pushPort: Int?
        /// State of the push listener.
        public let push: Push?

        enum CodingKeys: String, CodingKey {
            case interval, workers, hosts, services, status, port, fingerprint, traps, push
            case retentionRawHours = "retention_raw_hours"
            case retention5mDays = "retention_5m_days"
            case retention1hDays = "retention_1h_days"
            case publicKey = "public_key"
            case trapPort = "trap_port"
            case pushPort = "push_port"
        }
    }

    /// Request of ``Monitor64/updateSettings(_:)``. Schema `Monitor64SettingsInput`.
    public struct Monitor64SettingsInput: Codable, Hashable, Sendable {
        /// Default interval of new hosts in seconds, 30–900.
        public var interval: Int
        /// Concurrent queries, 1–512 (applies after the next start of the module).
        public var workers: Int
        /// Port of the trap receiver, 1–65535 (applied immediately; `nil` = unchanged).
        public var trapPort: Int?
        /// Port for agents in push mode, 1–65535 (applied immediately; `nil` = unchanged).
        public var pushPort: Int?

        /// Creates an input.
        public init(interval: Int, workers: Int, trapPort: Int? = nil, pushPort: Int? = nil) {
            self.interval = interval
            self.workers = workers
            self.trapPort = trapPort
            self.pushPort = pushPort
        }

        enum CodingKeys: String, CodingKey {
            case interval, workers
            case trapPort = "trap_port"
            case pushPort = "push_port"
        }
    }
}
