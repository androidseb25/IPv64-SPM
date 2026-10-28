import Foundation

extension Node64.Honeypot {
    /// State of the trap services: ports, open/error, connections since start, hints about skipped
    /// or reserved ports, and counters of sensor and storage.
    ///
    /// `GET /honeypot/status`
    public func status() async throws -> Node64.Honeypot64Status {
        try await client.send(Request(.get, "/honeypot/status"))
    }

    /// Statistics of a period: numbers, rankings and timeline (per hour up to 48 hours, otherwise per day). At most the retention.
    ///
    /// - Parameters:
    ///   - since: `24h` (default), `7d`, `<n>d` or a duration like `12h`. Invalid periods fail with 400.
    ///   - top: Length of the rankings (default 10, at most 100).
    ///
    /// `GET /honeypot/stats`
    public func stats(since: String? = nil, top: Int? = nil) async throws -> Node64.Honeypot64Stats {
        try await client.send(Request(.get, "/honeypot/stats", query: [QueryItem("since", since), QueryItem("top", top)]))
    }

    /// Latest events, newest first. Credentials are in plain text (honeypot only); payload as hex and escaped ASCII.
    ///
    /// - Parameters:
    ///   - limit: Number (default 50, at most 1000).
    ///   - source: Only events of this sensor (invalid = 400).
    ///   - country: Only events from this country (ISO 3166 alpha-2, any case). Without country data the list is empty.
    ///
    /// `GET /honeypot/events`
    public func events(
        limit: Int? = nil,
        source: Node64.Honeypot64Source? = nil,
        country: String? = nil
    ) async throws -> [Node64.Honeypot64Event] {
        try await client.send(Request(.get, "/honeypot/events", query: [
            QueryItem("limit", limit), QueryItem("source", source), QueryItem("country", country),
        ]))
    }

    /// Deletes all stored events of this node (settings remain). Recorded in the audit log (`honeypot.clear`).
    ///
    /// `DELETE /honeypot/events`
    public func clearEvents() async throws -> Node64.Honeypot64DeleteResult {
        try await client.send(Request(.delete, "/honeypot/events"))
    }

    /// Settings (sensor profile, services, reporting, logs).
    ///
    /// `GET /honeypot/config`
    public func settings() async throws -> Node64.Honeypot64Config {
        try await client.send(Request(.get, "/honeypot/config"))
    }

    /// Changes the settings. When `report` is switched on, the reported period starts now.
    ///
    /// Invalid values fail with 400 and `fields` naming the error per field. The spec does not say
    /// whether omitted fields are kept, so start from ``settings()`` and send the complete configuration.
    ///
    /// `PUT /honeypot/config`
    public func updateSettings(_ config: Node64.Honeypot64Config) async throws -> Node64.Honeypot64Config {
        try await client.send(Request(.put, "/honeypot/config", body: .json(config)))
    }

    /// Service catalog with the saved selection and the state per port
    /// (`free`, `open`, `error`, `used`, `reserved`). Save via ``updateSettings(_:)`` with profile `custom` and `services`.
    ///
    /// `GET /honeypot/catalog`
    public func catalog() async throws -> Node64.Honeypot64Catalog {
        try await client.send(Request(.get, "/honeypot/catalog"))
    }

    /// Live map: attacks of the last minutes with country and map point (newest first, at most 500) and
    /// the target of the arcs. x/y are coordinates of the country map (viewBox 0 0 1000 436).
    ///
    /// - Parameter minutes: Period in minutes (default 60, 1 to 1440).
    ///
    /// `GET /honeypot/live`
    public func live(minutes: Int? = nil) async throws -> Node64.Honeypot64Live {
        try await client.send(Request(.get, "/honeypot/live", query: [QueryItem("minutes", minutes)]))
    }
}
