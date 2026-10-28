import Foundation

extension Node64 {
    /// An API key of the signed-in user. The key itself is never returned after creation.
    ///
    /// Schema `APIKey`.
    public struct APIKey: Codable, Hashable, Sendable, Identifiable {
        /// Numeric key ID.
        public let id: Int
        /// Name of the key.
        public let name: String?
        /// Short hint (the last characters) to recognize the key.
        public let hint: String?
        /// Creation time.
        public let createdAt: Date?
        /// Time of the last request made with this key.
        public let lastUsedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, name, hint
            case createdAt = "created_at"
            case lastUsedAt = "last_used_at"
        }
    }

    /// Result of ``Node64/Node/APIKeys/create(name:)``. The key is only part of this response.
    public struct NodeCreatedAPIKey: Codable, Hashable, Sendable, Identifiable {
        /// Numeric key ID.
        public let id: Int
        /// Name of the key.
        public let name: String?
        /// Short hint (the last characters) to recognize the key.
        public let hint: String?
        /// Creation time.
        public let createdAt: Date?
        /// The secret API key. It is shown only once; store it securely.
        public let key: String?

        enum CodingKeys: String, CodingKey {
            case id, name, hint, key
            case createdAt = "created_at"
        }
    }

    /// An entry of the audit log.
    ///
    /// Schema `AuditEntry`.
    public struct AuditEntry: Codable, Hashable, Sendable, Identifiable {
        /// Numeric entry ID (use as `before` cursor).
        public let id: Int
        /// Time of the action.
        public let time: Date?
        /// Who performed the action.
        public let actor: String?
        /// Action name.
        public let action: String?
        /// Object the action applied to.
        public let target: String?
        /// Additional details.
        public let details: String?
        /// IP address of the caller.
        public let ip: String?
        /// Origin: `local` (UI), `api:<key name> (<hint>)` or `peer` (other node of the group).
        public let origin: String?
    }

    /// State of a module of the node.
    ///
    /// Schema `ModuleStatus`.
    public struct ModuleStatus: Codable, Hashable, Sendable, Identifiable {
        /// Module name (also its identifier).
        public let name: String
        /// Version of the module (own SemVer count per module).
        public let version: String?
        /// The module is available on this node.
        public let available: Bool?
        /// The module is switched on.
        public let enabled: Bool?
        /// The module is running.
        public let running: Bool?
        /// URL path of the module.
        public let path: String?
        /// Last error of the module.
        public let lastError: String?
        /// Date of the newest version in the changelog.
        ///
        /// Described only in the prose of `GET /modules`, not in the schema.
        public let changed: String?
        /// Changelog (Markdown), only with ``Node64/Node/Modules/list(changelog:)`` and `changelog: true`.
        ///
        /// Not in the schema; the key name `changelog` is inferred from the description, so the value is kept as raw JSON.
        public let changelog: JSONValue?

        public var id: String { name }

        enum CodingKeys: String, CodingKey {
            case name, version, available, enabled, running, path
            case lastError = "last_error"
            case changed, changelog
        }
    }

    /// Log level of the node.
    public struct LogLevel: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `debug`
        public static let debug: LogLevel = "debug"
        /// `info`
        public static let info: LogLevel = "info"
        /// `warn`
        public static let warn: LogLevel = "warn"
        /// `error`
        public static let error: LogLevel = "error"
        /// `inherit`: only valid for per-module levels, uses the global level.
        public static let inherit: LogLevel = "inherit"
    }

    /// Result of ``Node64/Node/status()``.
    public struct NodeStatus: Codable, Hashable, Sendable {
        /// Facts about this node.
        public let node: NodeStatusNode?
        /// State of the link to ipv64.
        public let link: LinkStatus?
        /// All modules with their state.
        public let modules: [ModuleStatus]?
        /// Summary per module.
        public let boards: [NodeStatusBoard]?
    }

    /// The `node` object of ``NodeStatus``.
    public struct NodeStatusNode: Codable, Hashable, Sendable {
        /// Node ID.
        public let id: String?
        /// Node name.
        public let name: String?
        /// Location.
        public let location: String?
        /// Time zone.
        public let timezone: String?
        /// Software version.
        public let version: String?
        /// Start time of the node process.
        public let startedAt: Date?
        /// Seconds since start.
        public let uptimeSeconds: Int?
        /// Size of the database in bytes.
        public let databaseBytes: Int?
        /// Global log level.
        public let logLevel: String?

        enum CodingKeys: String, CodingKey {
            case id, name, location, timezone, version
            case startedAt = "started_at"
            case uptimeSeconds = "uptime_seconds"
            case databaseBytes = "database_bytes"
            case logLevel = "log_level"
        }
    }

    /// Summary of one module in ``NodeStatus``.
    public struct NodeStatusBoard: Codable, Hashable, Sendable {
        /// Module name.
        public let module: String?
        /// Number of items that are OK.
        public let ok: Int?
        /// Number of items that are down.
        public let down: Int?
        /// Number of paused items.
        public let paused: Int?
        /// Number of items in another state.
        public let other: Int?
    }

    /// Result of ``Node64/Node/logs(lines:)``.
    public struct LogOutput: Codable, Hashable, Sendable {
        /// Current global log level.
        public let level: String?
        /// The most recent log lines (free-form objects).
        public let lines: [JSONValue]?
    }

    /// Log levels (result of ``Node64/Node/logging()`` and ``Node64/Node/updateLogging(level:resetMinutes:modules:)``).
    public struct LogSettings: Codable, Hashable, Sendable {
        /// Global log level.
        public let level: LogLevel?
        /// Per-module overrides (level or `inherit`).
        public let modules: [String: String]?
        /// Names of all modules that accept a level (only returned by the `GET`).
        public let knownModules: [String]?

        enum CodingKeys: String, CodingKey {
            case level, modules
            case knownModules = "known_modules"
        }
    }

    /// Data retention and chart resolution.
    public struct NodeRetention: Codable, Hashable, Sendable {
        /// Days to keep raw measurements.
        public let rawDays: Int?
        /// Days to keep hourly aggregates, `0` = unlimited.
        public let hourlyDays: Int?
        /// Chart resolution.
        public let chartDetail: String?
        /// Days to keep the audit log, `0` = unlimited.
        public let auditDays: Int?
        /// Allowed values for the fields above (free-form).
        public let options: JSONValue?

        enum CodingKeys: String, CodingKey {
            case rawDays = "raw_days"
            case hourlyDays = "hourly_days"
            case chartDetail = "chart_detail"
            case auditDays = "audit_days"
            case options
        }
    }

    /// Result of ``Node64/Node/restoreBackup(_:password:)``.
    public struct BackupRestoreResult: Codable, Hashable, Sendable {
        /// The node restarts now.
        public let restarting: Bool?
        /// Database: size in bytes. Archive: number of files.
        public let bytes: Int?
    }

    /// How secrets are treated by ``Node64/Node/exportConfiguration(secrets:password:)``.
    public struct NodeExportSecrets: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Secrets are left out (default).
        public static let none: NodeExportSecrets = "none"
        /// Secrets are encrypted with a password.
        public static let password: NodeExportSecrets = "password"
    }

    /// Result of ``Node64/Node/importConfiguration(_:password:)``.
    public struct NodeImportResult: Codable, Hashable, Sendable {
        /// Number of imported items.
        public let imported: Int?
        /// Problems that occurred during the import.
        public let problems: [String]?
    }

    /// Result of ``Node64/Node/reset(password:keepChecks:)``.
    public struct NodeResetResult: Codable, Hashable, Sendable {
        /// The node restarts now.
        public let restarting: Bool?
        /// What could not be cleaned up online (link, CDN64 names, tunnel, local group). The reset ran anyway.
        public let cleanupProblems: [String]?

        enum CodingKeys: String, CodingKey {
            case restarting
            case cleanupProblems = "cleanup_problems"
        }
    }

    /// Result of ``Node64/Node/overview()``: figures for the dashboard.
    public struct NodeOverview: Codable, Hashable, Sendable {
        /// Facts about this node.
        public let node: NodeOverviewNode?
        /// Modules with their state.
        public let modules: [NodeOverviewModule]?
        /// Network traffic.
        public let traffic: NodeOverviewTraffic?
        /// Healthcheck figures.
        public let healthchecks: NodeOverviewHealthchecks?
        /// ipv64 account figures.
        public let account: NodeOverviewAccount?
        /// Latest version (if the update check is on).
        public let update: JSONValue?
    }

    /// The `node` object of ``NodeOverview``.
    public struct NodeOverviewNode: Codable, Hashable, Sendable {
        /// Node ID.
        public let id: String?
        /// Node name.
        public let name: String?
        /// Location.
        public let location: String?
        /// Software version.
        public let version: String?
        /// Start time of the node process.
        public let startedAt: Date?
        /// Size of the database in bytes.
        public let dbBytes: Int?

        enum CodingKeys: String, CodingKey {
            case id, name, location, version
            case startedAt = "started_at"
            case dbBytes = "db_bytes"
        }
    }

    /// A module entry of ``NodeOverview``.
    public struct NodeOverviewModule: Codable, Hashable, Sendable {
        /// Module name.
        public let name: String?
        /// Module version.
        public let version: String?
        /// The module is switched on.
        public let enabled: Bool?
        /// The module is running.
        public let running: Bool?
        /// Last error of the module.
        public let lastError: String?

        enum CodingKeys: String, CodingKey {
            case name, version, enabled, running
            case lastError = "last_error"
        }
    }

    /// The `traffic` object of ``NodeOverview``.
    public struct NodeOverviewTraffic: Codable, Hashable, Sendable {
        /// Traffic figures are available on this system.
        public let available: Bool?
        /// Bytes received since the node started.
        public let rxSinceStart: Int?
        /// Bytes sent since the node started.
        public let txSinceStart: Int?
        /// Bytes received in total.
        public let rxTotal: Int?
        /// Bytes sent in total.
        public let txTotal: Int?
        /// Start of the accounting period.
        public let since: Date?

        enum CodingKeys: String, CodingKey {
            case available, since
            case rxSinceStart = "rx_since_start"
            case txSinceStart = "tx_since_start"
            case rxTotal = "rx_total"
            case txTotal = "tx_total"
        }
    }

    /// The `healthchecks` object of ``NodeOverview``.
    public struct NodeOverviewHealthchecks: Codable, Hashable, Sendable {
        /// Number of checks per location.
        public let checksByLocation: [String: Int]?
        /// Number of known nodes.
        public let nodes: Int?
        /// Number of nodes that are online.
        public let nodesOnline: Int?

        enum CodingKeys: String, CodingKey {
            case nodes
            case checksByLocation = "checks_by_location"
            case nodesOnline = "nodes_online"
        }
    }

    /// The `account` object of ``NodeOverview``.
    public struct NodeOverviewAccount: Codable, Hashable, Sendable {
        /// Account name.
        public let account: String?
        /// Plan.
        public let plan: String?
        /// End of the plan.
        public let planUntil: Date?
        /// Time of the last account check.
        public let checkedAt: Date?
        /// Error of the last account check.
        public let error: String?
        /// Plan limits and their usage.
        public let limits: [NodeOverviewLimit]?

        enum CodingKeys: String, CodingKey {
            case account, plan, error, limits
            case planUntil = "plan_until"
            case checkedAt = "checked_at"
        }
    }

    /// A plan limit in ``NodeOverviewAccount``.
    public struct NodeOverviewLimit: Codable, Hashable, Sendable {
        /// Limit key.
        public let key: String?
        /// Used amount.
        public let used: Double?
        /// Maximum amount.
        public let max: Double?
        /// The limit is unlimited.
        public let unlimited: Bool?
        /// Usage in percent.
        public let pct: Int?
    }

    /// Size of a dashboard tile.
    public struct DashboardTileSize: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `s`
        public static let small: DashboardTileSize = "s"
        /// `m`
        public static let medium: DashboardTileSize = "m"
        /// `l`
        public static let large: DashboardTileSize = "l"
        /// `xl`
        public static let extraLarge: DashboardTileSize = "xl"
    }

    /// One tile of the dashboard layout.
    public struct DashboardTile: Codable, Hashable, Sendable, Identifiable {
        /// Tile ID, e.g. `board:healthchecks`, `incidents:healthchecks`, `card:dns64`, `chart:dns64`,
        /// `chart:cdn64`, `node`, `storage`, `modules`, `account`, `link`.
        public var id: String
        /// Width of the tile.
        public var size: DashboardTileSize?
        /// The tile is hidden.
        public var hidden: Bool?

        /// Creates a tile.
        public init(id: String, size: DashboardTileSize? = nil, hidden: Bool? = nil) {
            self.id = id
            self.size = size
            self.hidden = hidden
        }
    }

    /// Dashboard of the signed-in user: order, width and hidden tiles. Empty means the default.
    public struct DashboardLayout: Codable, Hashable, Sendable {
        /// Tiles in display order.
        public let items: [DashboardTile]?
    }
}
