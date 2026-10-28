import Foundation

extension IPv64 {
    /// Healthchecks 2.0 (ipv64-hub, Node64): checks with measuring points, channels, maintenance windows, incidents and nodes.
    public var hc2: HC2 { HC2(client: self) }

    /// Endpoints of the *Healthchecks 2.0* area. Resources live in the sub-namespaces
    /// ``checks``, ``channels``, ``maintenances``, ``incidents`` and ``nodes``.
    public struct HC2: Sendable {
        let client: IPv64

        /// Checks, their state, history and statistics.
        public var checks: Checks { Checks(client: client) }
        /// Notification channels.
        public var channels: Channels { Channels(client: client) }
        /// Maintenance windows.
        public var maintenances: Maintenances { Maintenances(client: client) }
        /// Incidents (periods of failure).
        public var incidents: Incidents { Incidents(client: client) }
        /// Node64 nodes.
        public var nodes: Nodes { Nodes(client: client) }

        /// Account: plan, limits and locations.
        ///
        /// `GET /hc2/account`
        public func account() async throws -> HC2Account {
            try await client.send(Request(.get, "/hc2/account"))
        }

        /// Notification settings (quiet hours, batching) as key/value strings, e.g. `notify.quiet_from`.
        ///
        /// `GET /hc2/settings`
        public func settings() async throws -> [String: String] {
            try await client.send(Request(.get, "/hc2/settings"))
        }

        /// Changes notification settings. Only the provided fields are changed.
        ///
        /// `PATCH /hc2/settings`
        public func updateSettings(_ settings: HC2SettingsInput) async throws -> [String: String] {
            try await client.send(Request(.patch, "/hc2/settings", body: .json(settings)))
        }

        /// Events of all checks, newest first.
        ///
        /// - Parameters:
        ///   - limit: Page size, at most 100.
        ///   - before: Only events with a smaller ID (older). Use `meta.nextBefore` of the previous page.
        ///   - after: Only events with a larger ID (newer, ascending order).
        ///   - since: Only events from this point in time.
        ///
        /// `GET /hc2/events`
        public func events(
            limit: Int? = nil,
            before: Int? = nil,
            after: Int? = nil,
            since: Date? = nil
        ) async throws -> IPv64Page<HC2Event, HC2PageMeta> {
            try await client.sendPage(Request(.get, "/hc2/events", query: [
                QueryItem("limit", limit),
                QueryItem("before", before),
                QueryItem("after", after),
                QueryItem("since", since),
            ]))
        }
    }
}

/// Notification settings of the account (`PATCH /hc2/settings`). Only non-`nil` fields are sent.
public struct HC2SettingsInput: Encodable, Hashable, Sendable {
    /// Enable quiet hours (`notify.quiet_enabled`).
    public var quietEnabled: Bool?
    /// Start of quiet hours, `HH:MM` (`notify.quiet_from`).
    public var quietFrom: String?
    /// End of quiet hours, `HH:MM` (`notify.quiet_to`).
    public var quietTo: String?
    /// Quiet days, `1-7` comma separated (`notify.quiet_days`).
    public var quietDays: String?
    /// Maximum notifications per hour, 0 = unlimited (`notify.rate_per_hour`).
    public var ratePerHour: Int?
    /// Number of notifications that triggers batching (`notify.batch_threshold`).
    public var batchThreshold: Int?
    /// Batching window in seconds (`notify.batch_window_seconds`).
    public var batchWindowSeconds: Int?

    /// Creates a settings body.
    public init(
        quietEnabled: Bool? = nil,
        quietFrom: String? = nil,
        quietTo: String? = nil,
        quietDays: String? = nil,
        ratePerHour: Int? = nil,
        batchThreshold: Int? = nil,
        batchWindowSeconds: Int? = nil
    ) {
        self.quietEnabled = quietEnabled
        self.quietFrom = quietFrom
        self.quietTo = quietTo
        self.quietDays = quietDays
        self.ratePerHour = ratePerHour
        self.batchThreshold = batchThreshold
        self.batchWindowSeconds = batchWindowSeconds
    }

    enum CodingKeys: String, CodingKey {
        case quietEnabled = "notify.quiet_enabled"
        case quietFrom = "notify.quiet_from"
        case quietTo = "notify.quiet_to"
        case quietDays = "notify.quiet_days"
        case ratePerHour = "notify.rate_per_hour"
        case batchThreshold = "notify.batch_threshold"
        case batchWindowSeconds = "notify.batch_window_seconds"
    }
}
