import Foundation

extension Node64.Proxy64 {
    /// Hosts: proxy, redirect, 404, TLS passthrough and status page hosts.
    public var hosts: Hosts { Hosts(client: client) }
    /// TCP/UDP streams.
    public var streams: Streams { Streams(client: client) }
    /// Access lists (basic auth users and IP rules).
    public var accessLists: AccessLists { AccessLists(client: client) }
    /// ipv64 blocklists and the country filter lists.
    public var blocklists: Blocklists { Blocklists(client: client) }
    /// Honeypot64 integration.
    public var honeypot: Honeypot { Honeypot(client: client) }
    /// Overload protection (limits and bans).
    public var limits: Limits { Limits(client: client) }
    /// CDN64 online connection (tunnel to ipv64).
    public var online: Online { Online(client: client) }

    /// Hosts of the PROXY64 area.
    public struct Hosts: Sendable { let client: Node64 }
    /// Streams of the PROXY64 area.
    public struct Streams: Sendable { let client: Node64 }
    /// Access lists of the PROXY64 area.
    public struct AccessLists: Sendable { let client: Node64 }
    /// Blocklists of the PROXY64 area.
    public struct Blocklists: Sendable { let client: Node64 }
    /// Honeypot64 settings of the PROXY64 area.
    public struct Honeypot: Sendable { let client: Node64 }
    /// Overload protection of the PROXY64 area.
    public struct Limits: Sendable { let client: Node64 }
    /// CDN64 online connection of the PROXY64 area.
    public struct Online: Sendable { let client: Node64 }

    /// State of PROXY64: ports of the entry point, number of hosts, cache.
    ///
    /// The spec only says "object"; the result is returned as free-form JSON.
    ///
    /// `GET /cdn64/status`
    public func status() async throws -> JSONValue {
        try await client.sendJSON(Request(.get, "/cdn64/status"))
    }

    /// Starts a reachability check of all targets now.
    ///
    /// `POST /cdn64/check`
    public func check() async throws -> Node64.Proxy64CheckResult {
        try await client.send(Request(.post, "/cdn64/check"))
    }

    /// The default page for unknown names.
    ///
    /// `GET /cdn64/default`
    public func defaultPage() async throws -> Node64.Proxy64DefaultPage {
        try await client.send(Request(.get, "/cdn64/default"))
    }

    /// Changes the default page for unknown names. Fields you leave `nil` stay unchanged.
    ///
    /// The address must be valid for mode `redirect`; the page must be non-empty and at most 64 KB
    /// for mode `html` (otherwise 422).
    ///
    /// `PUT /cdn64/default`
    public func updateDefaultPage(
        mode: Node64.Proxy64DefaultMode? = nil,
        url: String? = nil,
        html: String? = nil
    ) async throws -> Node64.Proxy64DefaultPage {
        let page = Node64.Proxy64DefaultPage(mode: mode, url: url, html: html)
        return try await client.send(Request(.put, "/cdn64/default", body: .json(page)))
    }

    /// The access log, newest first.
    ///
    /// Entries with a `reason` were rejected. Rejected requests are always logged (throttled);
    /// normal requests only when the access log is enabled. Fails with 503 if the module is not running.
    /// To page, pass the ID of the last entry as `before`.
    ///
    /// - Parameters:
    ///   - host: Only entries of this host ID.
    ///   - status: `2` to `5` = status class, `r` = rejected only.
    ///   - query: Search in path, client or user agent.
    ///   - before: Only entries with a smaller ID (paging).
    ///   - limit: 1-500, default 100.
    ///   - rejectedOnly: Only rejected entries (like `status=r`); sent as `rejected=1`.
    ///
    /// `GET /cdn64/log`
    public func log(
        host: Int? = nil,
        status: String? = nil,
        query: String? = nil,
        before: Int? = nil,
        limit: Int? = nil,
        rejectedOnly: Bool = false
    ) async throws -> [Node64.Proxy64LogEntry] {
        try await client.send(Request(.get, "/cdn64/log", query: [
            QueryItem("host", host),
            QueryItem("status", status),
            QueryItem("q", query),
            QueryItem("before", before),
            QueryItem("limit", limit),
            QueryItem("rejected", rejectedOnly ? "1" : nil),
        ]))
    }

    /// Requests per host and a timeline per hour.
    ///
    /// `timeline` holds per hour `requests`, `2xx`-`5xx`, `bytes`, `blocked` and `conn_blocked`;
    /// `hosts` holds sums per host ID (`0` = rejected connections without host). The spec only says
    /// "object"; the result is returned as free-form JSON. Fails with 503 if the module is not running.
    ///
    /// - Parameters:
    ///   - hours: 1-2160, default 24.
    ///   - host: Only this host ID.
    ///
    /// `GET /cdn64/stats`
    public func stats(hours: Int? = nil, host: Int? = nil) async throws -> JSONValue {
        try await client.sendJSON(Request(.get, "/cdn64/stats", query: [
            QueryItem("hours", hours),
            QueryItem("host", host),
        ]))
    }

    /// Retention of the access log.
    ///
    /// `GET /cdn64/settings`
    public func settings() async throws -> Node64.Proxy64Settings {
        try await client.send(Request(.get, "/cdn64/settings"))
    }

    /// Changes the access log settings. Fields left `nil` are not sent.
    ///
    /// - Parameters:
    ///   - logDays: Retention in days, 1-90 (otherwise 422).
    ///   - anonymize: Anonymize client addresses in the log.
    ///
    /// `PUT /cdn64/settings`
    public func updateSettings(logDays: Int? = nil, anonymize: Bool? = nil) async throws -> Node64.Proxy64Settings {
        let body = Node64.Proxy64Settings(logDays: logDays, anonymize: anonymize)
        return try await client.send(Request(.put, "/cdn64/settings", body: .json(body)))
    }
}
