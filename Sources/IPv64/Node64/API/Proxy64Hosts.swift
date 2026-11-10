import Foundation

extension Node64.Proxy64.Hosts {
    /// Hosts (proxy, redirect, 404, TLS passthrough, status page) with reachability, counters and certificate.
    ///
    /// - Parameter kind: Only hosts of this kind.
    ///
    /// `GET /cdn64/hosts`
    public func list(kind: Node64.ProxyHostKind? = nil) async throws -> [Node64.ProxyHost] {
        try await client.send(Request(.get, "/cdn64/hosts", query: [QueryItem("kind", kind)]))
    }

    /// Creates a host.
    ///
    /// Missing fields get defaults. Fails with 422 for invalid input (`field` may be `status_page_id`).
    ///
    /// `POST /cdn64/hosts`
    public func create(_ input: Node64.ProxyHostInput) async throws -> Node64.ProxyHost {
        try await client.send(Request(.post, "/cdn64/hosts", body: .json(input)))
    }

    /// A single host.
    ///
    /// `GET /cdn64/hosts/{id}`
    public func get(_ id: Int) async throws -> Node64.ProxyHost {
        try await client.send(Request(.get, "/cdn64/hosts/\(id)"))
    }

    /// Changes a host. Fields you leave `nil` stay unchanged.
    ///
    /// `PUT /cdn64/hosts/{id}`
    public func update(_ id: Int, _ input: Node64.ProxyHostInput) async throws -> Node64.ProxyHost {
        try await client.send(Request(.put, "/cdn64/hosts/\(id)", body: .json(input)))
    }

    /// Deletes a host.
    ///
    /// `DELETE /cdn64/hosts/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/cdn64/hosts/\(id)"))
    }

    /// Switches a host on.
    ///
    /// `POST /cdn64/hosts/{id}/enable`
    public func enable(_ id: Int) async throws -> Node64.ProxyHost {
        try await client.send(Request(.post, "/cdn64/hosts/\(id)/enable"))
    }

    /// Switches a host off.
    ///
    /// `POST /cdn64/hosts/{id}/disable`
    public func disable(_ id: Int) async throws -> Node64.ProxyHost {
        try await client.send(Request(.post, "/cdn64/hosts/\(id)/disable"))
    }

    /// Creates a health check for the target of this host (module Healthchecks).
    ///
    /// Fails with 422 if the host has no target or the Healthchecks module is off.
    ///
    /// `POST /cdn64/hosts/{id}/healthcheck`
    public func createHealthcheck(_ id: Int) async throws -> Node64.Proxy64HealthcheckResult {
        try await client.send(Request(.post, "/cdn64/hosts/\(id)/healthcheck"))
    }
}

extension Node64.Proxy64.Hosts {
    /// CDN64 servers and connections per server for the names of a host.
    ///
    /// Fails with 409 if no ipv64 account is linked or the name is not at CDN64 (`not_online`), or the
    /// portal uses a server per name (`not_configured`); 403 if the class may not choose; 502 if ipv64 is unreachable.
    ///
    /// `GET /cdn64/hosts/{id}/servers`
    public func servers(_ id: Int) async throws -> Node64.Proxy64Servers {
        try await client.send(Request(.get, "/cdn64/hosts/\(id)/servers"))
    }

    /// Sets CDN64 servers and connections per server for all names of a host.
    ///
    /// - Parameters:
    ///   - count: Servers; `0` = all, also future ones (only classes without an upper limit).
    ///   - sessions: Connections per server; `nil` = unchanged.
    ///
    /// Errors as for ``servers(_:)``; 422 if `count` is invalid.
    ///
    /// `PUT /cdn64/hosts/{id}/servers`
    public func updateServers(_ id: Int, count: Int, sessions: Int? = nil) async throws -> Node64.Proxy64Servers {
        try await client.send(Request(.put, "/cdn64/hosts/\(id)/servers", body: .json(Node64.Proxy64.ServersBody(count: count, sessions: sessions))))
    }

    /// Sets the CDN64 protection (pattern WAF, JA4) of the servers for all names of a host.
    ///
    /// Fields you leave `nil` stay unchanged. Fails with 409 if no ipv64 account is linked or the name is not
    /// at CDN64, 422 for an invalid `ja4`, 502 if ipv64 is unreachable.
    ///
    /// - Parameters:
    ///   - waf: Pattern WAF (modes 2/3).
    ///   - ja4: Attack tool detection (JA4).
    ///
    /// `PUT /cdn64/hosts/{id}/protection`
    public func updateProtection(_ id: Int, waf: Bool? = nil, ja4: Node64.CDNJA4Mode? = nil) async throws -> Node64.Proxy64HostProtection {
        try await client.send(Request(.put, "/cdn64/hosts/\(id)/protection", body: .json(ProtectionBody(waf: waf, ja4: ja4))))
    }

    /// Enters the names of a host as own records in DNS64 (home network directly instead of via the internet).
    ///
    /// IPv4 only as A, IPv6 only as AAAA, only addresses reachable in the home network. Existing entries
    /// (same type or CNAME) stay; wildcards and main domains are left out. Without addresses PROXY64 uses the
    /// suggested ones. Fails with 404 for an unknown host, 409 if DNS64 is off and 422 for an invalid address (field `ip`).
    ///
    /// `POST /cdn64/hosts/{id}/localdns`
    public func addLocalDNS(_ id: Int, ipv4: String? = nil, ipv6: String? = nil) async throws -> Node64.Proxy64LocalDNSResult {
        try await client.send(Request(.post, "/cdn64/hosts/\(id)/localdns", body: .json(LocalDNSBody(ipv4: ipv4, ipv6: ipv6))))
    }

    private struct ProtectionBody: Encodable, Sendable {
        let waf: Bool?
        let ja4: Node64.CDNJA4Mode?
    }

    private struct LocalDNSBody: Encodable, Sendable {
        let ipv4: String?
        let ipv6: String?
    }
}

extension Node64.Proxy64 {
    struct ServersBody: Encodable, Sendable {
        let count: Int
        let sessions: Int?
    }
}
