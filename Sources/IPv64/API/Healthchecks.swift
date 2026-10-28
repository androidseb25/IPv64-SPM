import Foundation

extension IPv64 {
    /// Classic healthchecks (push, icmp, tcp, http, keyword).
    public var healthchecks: Healthchecks { Healthchecks(client: self) }

    /// Endpoints of the *Healthchecks* area.
    public struct Healthchecks: Sendable {
        let client: IPv64

        /// All healthchecks.
        ///
        /// - Parameters:
        ///   - type: Only this kind.
        ///   - status: Only this status.
        ///
        /// `GET /healthchecks`
        public func list(type: HealthcheckType? = nil, status: HealthcheckStatus? = nil) async throws -> [Healthcheck] {
            try await client.send(Request(.get, "/healthchecks", query: [
                QueryItem("type", type), QueryItem("status", status),
            ]))
        }

        /// Creates a healthcheck.
        ///
        /// A push check returns `push.url`, which your system should call regularly.
        /// Active checks require `target` or `url`.
        ///
        /// - Parameters:
        ///   - name: Name.
        ///   - input: Further settings. Its `name` is ignored in favor of `name`.
        ///
        /// `POST /healthchecks`
        public func create(name: String, _ input: HealthcheckInput = HealthcheckInput()) async throws -> HealthcheckDetail {
            var input = input
            input.name = name
            return try await client.send(Request(.post, "/healthchecks", body: .json(input)))
        }

        /// A healthcheck with its latest events.
        ///
        /// `GET /healthchecks/{token}`
        public func get(_ token: String) async throws -> HealthcheckDetail {
            try await client.send(Request(.get, "/healthchecks/\(token)"))
        }

        /// Changes a healthcheck. Only non-`nil` fields of `input` are changed;
        /// changing `type` resets the check settings.
        ///
        /// `PATCH /healthchecks/{token}`
        public func update(_ token: String, _ input: HealthcheckInput) async throws -> HealthcheckDetail {
            try await client.send(Request(.patch, "/healthchecks/\(token)", body: .json(input)))
        }

        /// Deletes a healthcheck. Not possible while the check controls an active DNS failover.
        ///
        /// `DELETE /healthchecks/{token}`
        public func delete(_ token: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/healthchecks/\(token)"))
        }

        /// Pauses a healthcheck.
        ///
        /// `POST /healthchecks/{token}/pause`
        public func pause(_ token: String) async throws -> Healthcheck {
            try await client.send(Request(.post, "/healthchecks/\(token)/pause"))
        }

        /// Resumes a paused healthcheck.
        ///
        /// `POST /healthchecks/{token}/resume`
        public func resume(_ token: String) async throws -> Healthcheck {
            try await client.send(Request(.post, "/healthchecks/\(token)/resume"))
        }

        /// Generates a new token. The push URL changes; events, incidents and failover monitors are kept.
        ///
        /// `POST /healthchecks/{token}/rotate-token`
        public func rotateToken(_ token: String) async throws -> Healthcheck {
            try await client.send(Request(.post, "/healthchecks/\(token)/rotate-token"))
        }

        /// Events of a healthcheck.
        ///
        /// Without a cursor the newest events come first. With `after`, older events come first
        /// (ascending), which is ideal for continuously fetching new events.
        ///
        /// - Parameters:
        ///   - token: Healthcheck token.
        ///   - limit: Number of events (1 to 1000, default 100).
        ///   - before: Only events with a smaller ID.
        ///   - after: Only events with a larger ID, sorted ascending.
        ///   - since: Only events from this point in time.
        ///
        /// `GET /healthchecks/{token}/events`
        public func events(
            _ token: String,
            limit: Int? = nil,
            before: Int? = nil,
            after: Int? = nil,
            since: Date? = nil
        ) async throws -> IPv64Page<HealthcheckEvent, HealthcheckEventsMeta> {
            try await client.sendPage(Request(.get, "/healthchecks/\(token)/events", query: [
                QueryItem("limit", limit), QueryItem("before", before),
                QueryItem("after", after), QueryItem("since", since),
            ]))
        }

        /// Incidents of a healthcheck.
        ///
        /// - Parameters:
        ///   - token: Healthcheck token.
        ///   - limit: Number of incidents (1 to 500, default 50).
        ///
        /// `GET /healthchecks/{token}/incidents`
        public func incidents(_ token: String, limit: Int? = nil) async throws -> [Incident] {
            try await client.send(Request(.get, "/healthchecks/\(token)/incidents", query: [
                QueryItem("limit", limit),
            ]))
        }

        /// Availability and latency, calculated from the stored events, with a time series.
        ///
        /// - Parameters:
        ///   - token: Healthcheck token.
        ///   - range: Time range (`1h`, `24h`, `7d`, `30d`; default `24h`).
        ///
        /// `GET /healthchecks/{token}/stats`
        public func stats(_ token: String, range: HealthcheckStatsRange? = nil) async throws -> HealthcheckStats {
            try await client.send(Request(.get, "/healthchecks/\(token)/stats", query: [
                QueryItem("range", range),
            ]))
        }

        /// Sends a test message to all integrations of the check. At most one per 30 seconds.
        ///
        /// `POST /healthchecks/{token}/test-notification`
        public func sendTestNotification(_ token: String) async throws -> HealthcheckTestNotificationResult {
            try await client.send(Request(.post, "/healthchecks/\(token)/test-notification"))
        }
    }
}
