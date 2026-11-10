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

extension Node64.Proxy64 {
    /// State of the Docker sync: connection, containers with labels and settings.
    ///
    /// `GET /cdn64/docker`
    public func docker() async throws -> Node64.Proxy64Docker {
        try await client.send(Request(.get, "/cdn64/docker"))
    }

    /// Changes the Docker sync. Fields you leave `nil` stay unchanged.
    ///
    /// - Parameters:
    ///   - enabled: Create proxy hosts from Docker labels (`node64.proxy.*`).
    ///   - traefik: Also read `traefik.*` labels.
    ///   - dockerHost: Docker API of this node (`unix://` or `tcp://`, no `ssh://`); `""` = default.
    ///   - certificate: Certificate for new Docker hosts: `""`, `auto`, `ipv64`, `http` or `dns:<account>`.
    ///   - acceptTOS: Accept the Let's Encrypt terms; needed with `certificate` while the account has not accepted them.
    ///
    /// Fails with 422 for an invalid `docker_host` or `certificate`, or when the terms are not accepted (field `docker_cert`).
    /// The response is the state like ``docker()``.
    ///
    /// `PUT /cdn64/docker`
    public func updateDocker(
        enabled: Bool? = nil,
        traefik: Bool? = nil,
        dockerHost: String? = nil,
        certificate: String? = nil,
        acceptTOS: Bool? = nil
    ) async throws -> Node64.Proxy64Docker {
        let body = DockerBody(enabled: enabled, traefik: traefik, dockerHost: dockerHost, certificate: certificate, acceptTOS: acceptTOS)
        return try await client.send(Request(.put, "/cdn64/docker", body: .json(body)))
    }

    /// CDN64 statistics: what the CDN64 servers blocked for the names of the account, per name with WAF/JA4.
    ///
    /// Fails with 409 if no ipv64 account is linked and 502 if ipv64 is unreachable.
    ///
    /// - Parameter days: `1` (today), `7` (default) or `30`.
    ///
    /// `GET /cdn64/protection`
    public func protection(days: Int? = nil) async throws -> Node64.Proxy64ProtectionStats {
        try await client.send(Request(.get, "/cdn64/protection", query: [QueryItem("days", days)]))
    }

    /// Lifts an automatic block and adds the address to the allow list.
    ///
    /// Fails with 404 if there is no automatic block for the address and 422 for an invalid `from`.
    ///
    /// - Parameters:
    ///   - ip: IP address or /64.
    ///   - from: Which block to lift; `nil` or ``Node64/Proxy64ReleaseSource/both`` = both.
    ///
    /// `POST /cdn64/release`
    public func release(ip: String, from: Node64.Proxy64ReleaseSource? = nil) async throws -> Node64.CDNBlocklists {
        try await client.send(Request(.post, "/cdn64/release", body: .json(ReleaseBody(ip: ip, from: from))))
    }

    private struct DockerBody: Encodable, Sendable {
        let enabled: Bool?
        let traefik: Bool?
        let dockerHost: String?
        let certificate: String?
        let acceptTOS: Bool?

        enum CodingKeys: String, CodingKey {
            case enabled, traefik
            case dockerHost = "docker_host"
            case certificate
            case acceptTOS = "accept_tos"
        }
    }

    private struct ReleaseBody: Encodable, Sendable {
        let ip: String
        let from: Node64.Proxy64ReleaseSource?
    }
}
