import Foundation

extension Node64.Node {
    /// Dashboard data: node, modules, a summary per module and the link state.
    ///
    /// `GET /status`
    public func status() async throws -> Node64.NodeStatus {
        try await client.send(Request(.get, "/status"))
    }

    /// Reads the settings as a key-value object.
    ///
    /// Keys: `node.name`, `node.location`, `node.timezone`, `node.base_url`, `notify.quiet_enabled` (0/1),
    /// `notify.quiet_from`, `notify.quiet_to` (HH:MM), `notify.quiet_days` (1 = Monday … 7 = Sunday, empty = no day),
    /// `notify.quiet_tz`, `notify.rate_per_hour` (0–1000 per channel, 0 = unlimited), `notify.batch_threshold` (0–100),
    /// `notify.batch_window_seconds` (0–600), `updates.check`.
    ///
    /// `GET /settings`
    public func settings() async throws -> [String: String] {
        try await client.send(Request(.get, "/settings"))
    }

    /// Changes settings. Only the keys you send are changed.
    ///
    /// Renaming (`node.name`, `node.location`) is forwarded to ipv64 and the other nodes, as in the UI.
    /// `node.name` must be 1–64 characters. Fails with `422` for an unknown key or invalid value.
    ///
    /// - Returns: The settings after the change.
    ///
    /// `PUT /settings`
    public func updateSettings(_ settings: [String: String]) async throws -> [String: String] {
        try await client.send(Request(.put, "/settings", body: .json(settings)))
    }

    /// Reads the audit log, newest first.
    ///
    /// Page by passing the ID of the last entry as `before`.
    ///
    /// `GET /audit`
    public func audit(limit: Int? = nil, before: Int? = nil) async throws -> [Node64.AuditEntry] {
        try await client.send(Request(.get, "/audit", query: [QueryItem("limit", limit), QueryItem("before", before)]))
    }

    /// Returns the most recent log lines.
    ///
    /// - Parameter lines: Number of lines (server default 200).
    ///
    /// `GET /logs`
    public func logs(lines: Int? = nil) async throws -> Node64.LogOutput {
        try await client.send(Request(.get, "/logs", query: [QueryItem("lines", lines)]))
    }

    /// Reads the log levels (global and per module).
    ///
    /// `GET /logging`
    public func logging() async throws -> Node64.LogSettings {
        try await client.send(Request(.get, "/logging"))
    }

    /// Changes the log levels. Fails with `422` for an invalid level or unknown module (see ``Node64/LogSettings/knownModules``).
    ///
    /// - Parameters:
    ///   - level: New global level.
    ///   - resetMinutes: Reset `debug` after this many minutes, `0` = never.
    ///   - modules: Per-module levels; use `inherit` to follow the global level.
    ///
    /// `PUT /logging`
    public func updateLogging(
        level: Node64.LogLevel? = nil,
        resetMinutes: Int? = nil,
        modules: [String: String]? = nil
    ) async throws -> Node64.LogSettings {
        try await client.send(Request(.put, "/logging", body: .json(LoggingBody(level: level, resetMinutes: resetMinutes, modules: modules))))
    }

    /// Reads data retention of the measurements and the chart resolution.
    ///
    /// `GET /retention`
    public func retention() async throws -> Node64.NodeRetention {
        try await client.send(Request(.get, "/retention"))
    }

    /// Changes data retention. Only the fields you pass are changed; fails with `422` for a value that is not allowed.
    ///
    /// - Parameters:
    ///   - rawDays: Days to keep raw measurements.
    ///   - hourlyDays: Days to keep hourly aggregates, `0` = unlimited.
    ///   - chartDetail: Chart resolution (see ``Node64/NodeRetention/options``).
    ///   - auditDays: Days to keep the audit log, `0` = unlimited.
    ///
    /// `PUT /retention`
    public func updateRetention(
        rawDays: Int? = nil,
        hourlyDays: Int? = nil,
        chartDetail: String? = nil,
        auditDays: Int? = nil
    ) async throws -> Node64.NodeRetention {
        let body = RetentionBody(rawDays: rawDays, hourlyDays: hourlyDays, chartDetail: chartDetail, auditDays: auditDays)
        return try await client.send(Request(.put, "/retention", body: .json(body)))
    }

    /// Figures for the dashboard: node, modules, traffic, healthchecks, ipv64 account, update.
    ///
    /// `GET /overview`
    public func overview() async throws -> Node64.NodeOverview {
        try await client.send(Request(.get, "/overview"))
    }

    /// Reads the dashboard layout of the signed-in user. Empty means the default layout.
    ///
    /// `GET /dashboard/layout`
    public func dashboardLayout() async throws -> Node64.DashboardLayout {
        try await client.send(Request(.get, "/dashboard/layout"))
    }

    /// Saves the dashboard layout (per user), replacing the stored one. Unknown tiles are ignored when displayed,
    /// new tiles appear at the end.
    ///
    /// Fails with `422` for an invalid tile ID or size.
    ///
    /// `PUT /dashboard/layout`
    public func updateDashboardLayout(_ items: [Node64.DashboardTile]) async throws -> Node64.DashboardLayout {
        try await client.send(Request(.put, "/dashboard/layout", body: .json(DashboardBody(items: items))))
    }

    /// Resets the dashboard to the default layout.
    ///
    /// `DELETE /dashboard/layout`
    public func resetDashboardLayout() async throws {
        try await client.sendWithoutContent(Request(.delete, "/dashboard/layout"))
    }

    /// The OpenAPI 3.1 description of the node API.
    ///
    /// `GET /openapi.json`
    public func openAPI() async throws -> JSONValue {
        try await client.sendJSON(Request(.get, "/openapi.json"))
    }

    private struct LoggingBody: Encodable, Sendable {
        let level: Node64.LogLevel?
        let resetMinutes: Int?
        let modules: [String: String]?

        enum CodingKeys: String, CodingKey {
            case level, modules
            case resetMinutes = "reset_minutes"
        }
    }

    private struct RetentionBody: Encodable, Sendable {
        let rawDays: Int?
        let hourlyDays: Int?
        let chartDetail: String?
        let auditDays: Int?

        enum CodingKeys: String, CodingKey {
            case rawDays = "raw_days"
            case hourlyDays = "hourly_days"
            case chartDetail = "chart_detail"
            case auditDays = "audit_days"
        }
    }

    private struct DashboardBody: Encodable, Sendable {
        let items: [Node64.DashboardTile]
    }
}

// MARK: - Modules

extension Node64.Node {
    /// Modules of the node (DNS64, PROXY64, healthchecks, …).
    public var modules: Modules { Modules(client: client) }

    /// Endpoints for the modules of the node (`/modules`).
    public struct Modules: Sendable {
        let client: Node64

        /// Lists the modules with their state.
        ///
        /// Per module: name, version (own SemVer count per module), date of the newest changelog version,
        /// availability, enabled/running state, path and last error.
        ///
        /// - Parameter changelog: Also return the changelog (Markdown) of each module.
        ///
        /// `GET /modules`
        public func list(changelog: Bool = false) async throws -> [Node64.ModuleStatus] {
            try await client.send(Request(.get, "/modules", query: [QueryItem("changelog", changelog ? "1" : nil)]))
        }

        /// Switches a module on. It starts immediately, without a restart.
        ///
        /// Fails with `422` if the module is not available. The spec documents no response body,
        /// so the raw JSON is returned.
        ///
        /// - Parameter name: Module name.
        ///
        /// `POST /modules/{name}/enable`
        @discardableResult
        public func enable(_ name: String) async throws -> JSONValue {
            try await client.sendJSON(Request(.post, "/modules/\(name)/enable"))
        }

        /// Switches a module off.
        ///
        /// The spec documents no response body, so the raw JSON is returned.
        ///
        /// - Parameter name: Module name.
        ///
        /// `POST /modules/{name}/disable`
        @discardableResult
        public func disable(_ name: String) async throws -> JSONValue {
            try await client.sendJSON(Request(.post, "/modules/\(name)/disable"))
        }
    }
}

// MARK: - API keys

extension Node64.Node {
    /// API keys of the signed-in user.
    public var apiKeys: APIKeys { APIKeys(client: client) }

    /// Endpoints for the API keys of the node (`/keys`).
    public struct APIKeys: Sendable {
        let client: Node64

        /// Lists the API keys of the user (without the key itself).
        ///
        /// `GET /keys`
        public func list() async throws -> [Node64.APIKey] {
            try await client.send(Request(.get, "/keys"))
        }

        /// Creates an API key. The key is only part of this response; store it securely.
        ///
        /// - Parameter name: Name of the key, 1–100 characters.
        ///
        /// `POST /keys`
        public func create(name: String) async throws -> Node64.NodeCreatedAPIKey {
            try await client.send(Request(.post, "/keys", body: .json(Body(name: name))))
        }

        /// Revokes (deletes) an API key. Clients using it lose access immediately.
        ///
        /// - Parameter id: Numeric key ID.
        ///
        /// `DELETE /keys/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/keys/\(id)"))
        }

        private struct Body: Encodable, Sendable {
            let name: String
        }
    }
}
