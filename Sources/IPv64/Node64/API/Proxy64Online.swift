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
