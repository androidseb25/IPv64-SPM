import Foundation

extension Node64.Proxy64.AccessLists {
    /// Access lists (without passwords) with the hosts that use them.
    ///
    /// `GET /cdn64/access-lists`
    public func list() async throws -> [Node64.CDNAccessListEntry] {
        try await client.send(Request(.get, "/cdn64/access-lists"))
    }

    /// Creates an access list.
    ///
    /// `POST /cdn64/access-lists`
    public func create(_ input: Node64.CDNAccessListInput) async throws -> Node64.CDNAccessList {
        try await client.send(Request(.post, "/cdn64/access-lists", body: .json(input)))
    }

    /// A single access list.
    ///
    /// `GET /cdn64/access-lists/{id}`
    public func get(_ id: Int) async throws -> Node64.CDNAccessList {
        try await client.send(Request(.get, "/cdn64/access-lists/\(id)"))
    }

    /// Changes an access list. `users` replaces the users; an empty password keeps the existing one.
    ///
    /// `PUT /cdn64/access-lists/{id}`
    public func update(_ id: Int, _ input: Node64.CDNAccessListInput) async throws -> Node64.CDNAccessList {
        try await client.send(Request(.put, "/cdn64/access-lists/\(id)", body: .json(input)))
    }

    /// Deletes an access list. Fails with 409 while a host still uses it.
    ///
    /// `DELETE /cdn64/access-lists/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/cdn64/access-lists/\(id)"))
    }
}

extension Node64.Proxy64.Blocklists {
    /// State of the ipv64 blocklists.
    ///
    /// Fails with 503 if the module is not running.
    ///
    /// `GET /cdn64/blocklists`
    public func get() async throws -> Node64.CDNBlocklists {
        try await client.send(Request(.get, "/cdn64/blocklists"))
    }

    /// Switches blocklists on or off and sets exceptions.
    ///
    /// Rejection happens at the entry point before TLS and before any access list, for proxy hosts,
    /// passthrough hosts and streams. The lists come from ipv64.net and refresh every 30 minutes.
    /// Honeypot lists are loaded live when a list token is stored, otherwise as the daily snapshot.
    /// Fails with 422 for an unknown list, an invalid exception or an invalid list token.
    ///
    /// - Parameters:
    ///   - enabled: IDs of the lists to switch on.
    ///   - allow: Exceptions: IP addresses or networks.
    ///   - token: List token from the ipv64 account (32 characters A-Z, a-z, 0-9) for the live edition
    ///     of the honeypot lists. `""` deletes it, `nil` leaves it unchanged. If only `token` is sent,
    ///     enabled lists and exceptions stay unchanged. The token is stored encrypted and never returned.
    ///
    /// `PUT /cdn64/blocklists`
    public func update(
        enabled: [String]? = nil,
        allow: [String]? = nil,
        token: String? = nil
    ) async throws -> Node64.CDNBlocklists {
        let body = UpdateBody(enabled: enabled, allow: allow, token: token)
        return try await client.send(Request(.put, "/cdn64/blocklists", body: .json(body)))
    }

    /// Reloads the ipv64 blocklists now (accepted, `202`).
    ///
    /// `POST /cdn64/blocklists/refresh`
    public func refresh() async throws -> Node64.CDNBlocklists {
        try await client.send(Request(.post, "/cdn64/blocklists/refresh"))
    }

    private struct UpdateBody: Encodable, Sendable {
        let enabled: [String]?
        let allow: [String]?
        let token: String?
    }
}

extension Node64.Proxy64.Honeypot {
    /// Honeypot64 settings, blocked IPs and counters.
    ///
    /// `decoyAvailable` and `accessAvailable` tell whether Honeypot64 currently offers a web decoy
    /// and evaluates accesses. Fails with 503 if the module is not running.
    ///
    /// `GET /cdn64/honeypot`
    public func get() async throws -> Node64.CDNHoneypotView {
        try await client.send(Request(.get, "/cdn64/honeypot"))
    }

    /// Changes the Honeypot64 settings. Fields left `nil` are not sent and stay unchanged;
    /// switching blocking off clears the block list.
    ///
    /// `blockHours` must be 1-720 (otherwise 422).
    ///
    /// `PUT /cdn64/honeypot`
    public func update(_ settings: Node64.CDNHoneypotSettings) async throws -> Node64.CDNHoneypotView {
        try await client.send(Request(.put, "/cdn64/honeypot", body: .json(settings)))
    }

    /// Lifts the Honeypot64 block of an IP. Fails with 404 if it is not blocked.
    ///
    /// - Parameter ip: IPv4 or IPv6 address exactly as listed in ``Node64/CDNHoneypotView/blocks``.
    ///
    /// `DELETE /cdn64/honeypot/blocks/{ip}`
    public func unblock(_ ip: String) async throws {
        try await client.sendWithoutContent(Request(.delete, "/cdn64/honeypot/blocks/\(ip)"))
    }
}

extension Node64.Proxy64.Limits {
    /// Overload protection: settings, defaults, bans and counters.
    ///
    /// Fails with 503 if the module is not running.
    ///
    /// `GET /cdn64/limits`
    public func get() async throws -> Node64.CDNLimitsView {
        try await client.send(Request(.get, "/cdn64/limits"))
    }

    /// Changes the overload protection. Fields left `nil` are not sent and stay unchanged;
    /// `0` switches a limit off.
    ///
    /// Fails with 422 for values out of range.
    ///
    /// `PUT /cdn64/limits`
    public func update(_ limits: Node64.CDNLimits) async throws -> Node64.CDNLimitsView {
        try await client.send(Request(.put, "/cdn64/limits", body: .json(limits)))
    }

    /// Lifts the ban of an address. Fails with 404 if it is not banned.
    ///
    /// - Parameter ip: IPv4 address or IPv6 /64 exactly as listed in ``Node64/CDNLimitsView/bans``
    ///   (percent-encoded as one path segment).
    ///
    /// `DELETE /cdn64/limits/bans/{ip}`
    public func unban(_ ip: String) async throws {
        try await client.sendWithoutContent(Request(.delete, "/cdn64/limits/bans/\(ip)"))
    }
}
