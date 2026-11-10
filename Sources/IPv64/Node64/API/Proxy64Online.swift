import Foundation

extension Node64.Proxy64.Online {
    /// CDN64 online connection: tunnel, servers, enabled names, quota.
    ///
    /// `GET /cdn64/online`
    public func status() async throws -> Node64.CDNOnlineStatus {
        try await client.send(Request(.get, "/cdn64/online"))
    }

    /// Sets the tunnel by hand (for tests; normally it is set up by a click via ``registerTunnel()``).
    ///
    /// Fails with 422 if the data is incomplete.
    ///
    /// `PUT /cdn64/online`
    public func setTunnel(_ input: Node64.CDNOnlineTunnelInput) async throws -> Node64.CDNOnlineStatus {
        try await client.send(Request(.put, "/cdn64/online", body: .json(input)))
    }

    /// Forgets the tunnel on this node (it stays at ipv64).
    ///
    /// `DELETE /cdn64/online`
    public func forgetTunnel() async throws {
        try await client.sendWithoutContent(Request(.delete, "/cdn64/online"))
    }

    /// Registers the tunnel at ipv64 or checks it, and waits up to 25 s for the connection.
    ///
    /// Creates the tunnel if none exists (token stored encrypted) and takes over the server list from
    /// ipv64. Errors carry a code such as `no_api_key` (409, no ipv64 account linked), 403 (key rejected,
    /// class without CDN, tunnel blocked) or 502 (ipv64 unreachable); read it via ``Node64Error/code``.
    ///
    /// `POST /cdn64/online/tunnel`
    public func registerTunnel() async throws -> Node64.CDNOnlineStatus {
        try await client.send(Request(.post, "/cdn64/online/tunnel"))
    }

    /// Switches on the names of a host at CDN64 (DNS points to srv07/srv08).
    ///
    /// Placeholder (wildcard) names are skipped; every name gets its own result. If all fail, the
    /// tunnel is removed again.
    ///
    /// - Parameters:
    ///   - host: Host ID.
    ///   - mode: `1` = pass through (default).
    ///   - healthcheck: Also create an online health check on the first name.
    ///
    /// `POST /cdn64/hosts/{id}/online`
    public func enable(host: Int, mode: Int? = nil, healthcheck: Bool? = nil) async throws -> Node64.CDNOnlineEnableResult {
        let body = EnableBody(mode: mode, healthcheck: healthcheck)
        return try await client.send(Request(.post, "/cdn64/hosts/\(host)/online", body: .json(body)))
    }

    /// Switches off all names of a host (DNS goes back); with the last name the tunnel goes too.
    ///
    /// `DELETE /cdn64/hosts/{id}/online`
    public func disable(host: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/cdn64/hosts/\(host)/online"))
    }

    /// Self-test over the internet: every name through every server and address.
    ///
    /// Fails with 409 if the host is not switched on.
    ///
    /// `POST /cdn64/hosts/{id}/online/test`
    public func test(host: Int) async throws -> [Node64.CDNOnlineTest] {
        try await client.send(Request(.post, "/cdn64/hosts/\(host)/online/test"))
    }

    private struct EnableBody: Encodable, Sendable {
        let mode: Int?
        let healthcheck: Bool?
    }
}

extension Node64.Proxy64.Online {
    /// Pauses or resumes CDN64 for the names of a host (DNS goes directly to the server, settings stay).
    ///
    /// Fails with 404 if unknown, 409 if no ipv64 account is linked or the name is not at CDN64, 502 if ipv64 is unreachable.
    ///
    /// `POST /cdn64/hosts/{id}/online/pause`
    public func pause(host: Int, paused: Bool) async throws {
        try await client.sendWithoutContent(Request(.post, "/cdn64/hosts/\(host)/online/pause", body: .json(PauseBody(paused: paused))))
    }

    /// Pauses or resumes a name this node does not manage (mode 3 of ipv64.net, other nodes).
    ///
    /// - Parameters:
    ///   - remoteID: ID of the name at ipv64 (``Node64/CDNOnlineName/remoteID`` from ``status()``).
    ///   - paused: `true` pauses, `false` resumes.
    ///
    /// Fails with 400 if invalid, 404 for an unknown name, 502 if ipv64 is unreachable.
    ///
    /// `POST /cdn64/online/names/{rid}/pause`
    public func pauseName(remoteID: Int, paused: Bool) async throws {
        try await client.sendWithoutContent(Request(.post, "/cdn64/online/names/\(remoteID)/pause", body: .json(PauseBody(paused: paused))))
    }

    /// CDN64 servers of the own tunnel (portal without a server per name).
    ///
    /// Fails with 409 if no ipv64 account is linked or the name is not at CDN64 (`not_online`), or the portal uses
    /// a server per name (`not_configured`); 403 if the class may not choose; 502 if ipv64 is unreachable.
    ///
    /// `GET /cdn64/online/servers`
    public func servers() async throws -> Node64.Proxy64Servers {
        try await client.send(Request(.get, "/cdn64/online/servers"))
    }

    /// Sets the CDN64 servers of the own tunnel.
    ///
    /// - Parameters:
    ///   - count: Servers; `0` = all, also future ones (only classes without an upper limit).
    ///   - sessions: Connections per server; `nil` = unchanged.
    ///
    /// Errors as for ``servers()``; 422 if `count` is invalid.
    ///
    /// `PUT /cdn64/online/servers`
    public func updateServers(count: Int, sessions: Int? = nil) async throws -> Node64.Proxy64Servers {
        try await client.send(Request(.put, "/cdn64/online/servers", body: .json(Node64.Proxy64.ServersBody(count: count, sessions: sessions))))
    }

    private struct PauseBody: Encodable, Sendable {
        let paused: Bool
    }
}
