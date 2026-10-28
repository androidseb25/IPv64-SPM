import Foundation

extension Node64.DynDNS {
    /// DynDNS targets.
    public var targets: Targets { Targets(client: client) }

    /// Endpoints below `/dyndns/targets`.
    public struct Targets: Sendable { let client: Node64 }

    /// Current state: public IPv4/IPv6 and prefix, connection hint (CGNAT/DS-Lite), targets by status and update limit.
    ///
    /// `limit` is only present with a central ipv64 API key. Without an enabled target the regular
    /// check rests; ``check()`` still checks.
    ///
    /// `GET /dyndns/status`
    public func status() async throws -> Node64.DynDNSStatus {
        try await client.send(Request(.get, "/dyndns/status"))
    }

    /// Checks now: determines the addresses and compares the targets.
    ///
    /// Waits up to 45 seconds and then returns the state like ``status()``; `.running` when the round takes longer (202).
    ///
    /// `POST /dyndns/check`
    public func check() async throws -> Node64.DynDNSCheckResult {
        let (data, response) = try await client.perform(Request(.post, "/dyndns/check"))
        if response.statusCode == 202 { return .running }
        return .completed(try client.decode(Node64.DynDNSStatus.self, from: data))
    }

    /// History of updates at ipv64 or IP checks (at most 300 entries, newest first; `truncated` shows whether there are more).
    ///
    /// The spec documents no response schema, so the raw JSON is returned (spec gap).
    ///
    /// - Parameters:
    ///   - type: `updates` (default) or `checks`.
    ///   - target: Only updates of this target.
    ///   - family: Only for `checks`: IPv4 or IPv6.
    ///   - days: Time range in days (default 7, 0 = everything).
    ///
    /// `GET /dyndns/history`
    public func history(
        type: Node64.DynDNSHistoryType? = nil,
        target: Int? = nil,
        family: Node64.DynDNSIPFamily? = nil,
        days: Int? = nil
    ) async throws -> JSONValue {
        try await client.sendJSON(Request(.get, "/dyndns/history", query: [
            QueryItem("type", type), QueryItem("target", target), QueryItem("family", family), QueryItem("days", days),
        ]))
    }

    /// Settings of the module.
    ///
    /// `GET /dyndns/settings`
    public func settings() async throws -> Node64.DynDNSSettings {
        try await client.send(Request(.get, "/dyndns/settings"))
    }

    /// Changes the settings. Omitted fields keep their value.
    ///
    /// `PUT /dyndns/settings`
    public func updateSettings(_ settings: Node64.DynDNSSettings) async throws -> Node64.DynDNSSettings {
        try await client.send(Request(.put, "/dyndns/settings", body: .json(settings)))
    }

    /// Names of the ipv64 account that can be chosen (without tokens), with existing A/AAAA records and suggested modes.
    ///
    /// Needs the central ipv64 API key (otherwise 409).
    ///
    /// `GET /dyndns/account/names`
    public func accountNames() async throws -> [Node64.DynDNSAccountName] {
        try await client.send(Request(.get, "/dyndns/account/names"))
    }
}

extension Node64.DynDNS.Targets {
    /// Lists all targets.
    ///
    /// `GET /dyndns/targets`
    public func list() async throws -> [Node64.DynDNSTarget] {
        try await client.send(Request(.get, "/dyndns/targets"))
    }

    /// Returns one target.
    ///
    /// `GET /dyndns/targets/{id}`
    public func get(_ id: Int) async throws -> Node64.DynDNSTarget {
        try await client.send(Request(.get, "/dyndns/targets/\(id)"))
    }

    /// Creates a target. Fails with 409 when domain and host already exist.
    ///
    /// `POST /dyndns/targets`
    public func create(_ input: Node64.DynDNSTargetInput) async throws -> Node64.DynDNSTarget {
        try await client.send(Request(.post, "/dyndns/targets", body: .json(input)))
    }

    /// Changes a target. Modes, addresses and `enabled` are taken as sent, so pass the complete
    /// target (start from ``get(_:)``) rather than only the changed fields; an empty `token` keeps the
    /// stored one. Domain and host cannot be changed (create a new target).
    ///
    /// `PUT /dyndns/targets/{id}`
    public func update(_ id: Int, _ input: Node64.DynDNSTargetInput) async throws -> Node64.DynDNSTarget {
        try await client.send(Request(.put, "/dyndns/targets/\(id)", body: .json(input)))
    }

    /// Deletes a target. The record at ipv64 and the history remain.
    ///
    /// `DELETE /dyndns/targets/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/dyndns/targets/\(id)"))
    }

    /// Updates now: reports the address to ipv64 immediately, even without a change (costs update limit),
    /// and lifts an automatic pause.
    ///
    /// `result` is `sent` or `nothing` (no current address known for the modes). Fails with 409 while a round is running.
    ///
    /// `POST /dyndns/targets/{id}/update`
    public func updateNow(_ id: Int) async throws -> Node64.DynDNSUpdateResult {
        try await client.send(Request(.post, "/dyndns/targets/\(id)/update"))
    }

    /// Fetches the record token from ipv64 again. Lifts a pause caused by `badauth`.
    ///
    /// Needs the central ipv64 API key (otherwise 409).
    ///
    /// `POST /dyndns/targets/{id}/token`
    public func refreshToken(_ id: Int) async throws -> Node64.DynDNSTarget {
        try await client.send(Request(.post, "/dyndns/targets/\(id)/token"))
    }

    /// Creates targets from names of the ipv64 account (see ``Node64/DynDNS/accountNames()``).
    ///
    /// Empty modes use the suggestion. The node fetches the record tokens itself. The response lists
    /// the created targets and the names not taken over; the spec documents no schema, so the raw JSON is returned (spec gap).
    ///
    /// `POST /dyndns/targets/from-account`
    @discardableResult
    public func createFromAccount(_ selections: [Node64.DynDNSAccountSelection]) async throws -> JSONValue {
        try await client.sendJSON(Request(.post, "/dyndns/targets/from-account", body: .json(selections)))
    }
}
