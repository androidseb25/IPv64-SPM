import Foundation

extension Node64.DNS64 {
    /// State of the DNS service: listen address, start time, router for local names, log retention and blocking.
    ///
    /// `GET /dns64/status`
    public func status() async throws -> Node64.DNS64Status {
        try await client.send(Request(.get, "/dns64/status"))
    }

    /// Key figures of a time range: queries, blocked, cached, clients, average upstream response time,
    /// blocklist size, cache counters and uptime.
    ///
    /// - Parameter range: Time range (default `24h`).
    ///
    /// `GET /dns64/summary`
    public func summary(range: Node64.DNS64Range? = nil) async throws -> Node64.DNS64Summary {
        try await client.send(Request(.get, "/dns64/summary", query: [QueryItem("range", range)]))
    }

    /// Queries over time as buckets. The bar width `stepMs` is 2 min (1h), 30 min (24h) or 4 h (7d).
    ///
    /// - Parameter range: Time range (default `24h`).
    ///
    /// `GET /dns64/timeline`
    public func timeline(range: Node64.DNS64Range? = nil) async throws -> Node64.DNS64Timeline {
        try await client.send(Request(.get, "/dns64/timeline", query: [QueryItem("range", range)]))
    }

    /// Top list of blocked domains, allowed domains or clients.
    ///
    /// - Parameters:
    ///   - kind: Which list.
    ///   - range: Time range (default `24h`).
    ///   - limit: Number of entries (default 10, maximum 100).
    ///
    /// `GET /dns64/top`
    public func top(
        kind: Node64.DNS64TopKind,
        range: Node64.DNS64Range? = nil,
        limit: Int? = nil
    ) async throws -> [Node64.DNS64TopItem] {
        try await client.send(Request(.get, "/dns64/top", query: [
            QueryItem("kind", kind),
            QueryItem("range", range),
            QueryItem("limit", limit),
        ]))
    }

    /// Query log, newest first. Page with `limit` and `offset`.
    ///
    /// - Parameters:
    ///   - status: Only queries with this status.
    ///   - query: Part of a domain or client IP (sent as `q`).
    ///   - limit: Rows per page (default 50, maximum 500).
    ///   - offset: Rows to skip (default 0).
    ///   - group: Only this device group (an empty string selects clients without a group).
    ///
    /// `GET /dns64/log`
    public func log(
        status: Node64.DNS64QueryStatus? = nil,
        query: String? = nil,
        limit: Int? = nil,
        offset: Int? = nil,
        group: String? = nil
    ) async throws -> Node64.DNS64Log {
        try await client.send(Request(.get, "/dns64/log", query: [
            QueryItem("status", status),
            QueryItem("q", query),
            QueryItem("limit", limit),
            QueryItem("offset", offset),
            QueryItem("group", group),
        ]))
    }

    /// Current settings of the resolver (encrypted DNS, certificates, upstream mode, lists, cache, log anonymization).
    ///
    /// `GET /dns64/settings`
    public func settings() async throws -> Node64.DNS64Settings {
        try await client.send(Request(.get, "/dns64/settings"))
    }

    /// Changes settings. Only the fields you set change (`nil` is not sent).
    ///
    /// `upstreams` and `lists` are replaced as a whole: to add or change one entry, read the current
    /// list with ``settings()``, modify it and send the complete list back. For single entries prefer
    /// ``Lists/add(_:name:)`` and ``Upstreams/add(_:name:ips:)``.
    ///
    /// The DNS service restarts afterwards. Works even if it is not running. Answers `409` if the
    /// settings were saved but the service does not start.
    ///
    /// - Returns: The new settings.
    ///
    /// `PUT /dns64/settings`
    @discardableResult
    public func updateSettings(_ input: Node64.DNS64SettingsInput) async throws -> Node64.DNS64Settings {
        try await client.send(Request(.put, "/dns64/settings", body: .json(input)))
    }

    /// Pauses blocking. The DNS service keeps running, only blocklists stop applying.
    ///
    /// - Parameter minutes: 1-1440 minutes, or 0 until ``resume()``.
    ///
    /// `POST /dns64/pause`
    @discardableResult
    public func pause(minutes: Int) async throws -> Node64.DNS64Blocking {
        try await client.send(Request(.post, "/dns64/pause", body: .json(PauseBody(minutes: minutes))))
    }

    /// Turns blocking on again.
    ///
    /// `POST /dns64/resume`
    @discardableResult
    public func resume() async throws -> Node64.DNS64Blocking {
        try await client.send(Request(.post, "/dns64/resume"))
    }

    /// The home-network CA certificate (DER, `application/x-x509-ca-cert`). Answers `404` if the node has no own CA.
    ///
    /// `GET /dns64/ca.crt`
    public func caCertificate() async throws -> Data {
        try await client.sendData(Request(.get, "/dns64/ca.crt"), accept: "application/x-x509-ca-cert")
    }

    /// Configuration profile for iOS and macOS (`application/x-apple-aspen-config`).
    ///
    /// - Parameters:
    ///   - transport: `doh` (default) or `dot` (sent as `proto`).
    ///   - host: Name or IP the devices use to reach the node.
    ///
    /// `GET /dns64/mobileconfig`
    public func mobileConfig(transport: Node64.DNS64Protocol? = nil, host: String? = nil) async throws -> Data {
        try await client.sendData(
            Request(.get, "/dns64/mobileconfig", query: [QueryItem("proto", transport), QueryItem("host", host)]),
            accept: "application/x-apple-aspen-config"
        )
    }

    /// Cache counters and flushing.
    public var cache: Cache { Cache(client: client) }
    /// Blocklists.
    public var lists: Lists { Lists(client: client) }
    /// Upstream servers.
    public var upstreams: Upstreams { Upstreams(client: client) }
    /// Allowed domains.
    public var allowlist: Allowlist { Allowlist(client: client) }
    /// Custom DNS records.
    public var records: Records { Records(client: client) }

    /// Cache endpoints of DNS64.
    public struct Cache: Sendable { let client: Node64 }
    /// Blocklist endpoints of DNS64.
    public struct Lists: Sendable { let client: Node64 }
    /// Upstream server endpoints of DNS64.
    public struct Upstreams: Sendable { let client: Node64 }
    /// Allowlist endpoints of DNS64.
    public struct Allowlist: Sendable { let client: Node64 }
    /// Custom record endpoints of DNS64.
    public struct Records: Sendable { let client: Node64 }
}

private struct PauseBody: Encodable, Sendable {
    let minutes: Int
}
