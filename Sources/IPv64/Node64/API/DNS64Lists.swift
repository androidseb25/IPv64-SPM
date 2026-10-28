import Foundation

extension Node64.DNS64.Lists {
    /// Blocklists with number of rules, last update and error.
    ///
    /// `GET /dns64/lists`
    public func list() async throws -> [Node64.DNS64ListStatus] {
        try await client.send(Request(.get, "/dns64/lists"))
    }

    /// Adds a custom blocklist (enabled). Answers `400` if invalid or already present.
    ///
    /// - Parameters:
    ///   - url: URL of the list.
    ///   - name: Display name.
    /// - Returns: The new settings.
    ///
    /// `POST /dns64/lists`
    @discardableResult
    public func add(_ url: String, name: String? = nil) async throws -> Node64.DNS64Settings {
        try await client.send(Request(.post, "/dns64/lists", body: .json(AddBody(name: name, url: url))))
    }

    /// Removes a custom blocklist. Answers `404` if there is no custom list with this URL.
    ///
    /// - Returns: The new settings.
    ///
    /// `DELETE /dns64/lists`
    @discardableResult
    public func remove(_ url: String) async throws -> Node64.DNS64Settings {
        try await client.send(Request(.delete, "/dns64/lists", query: [QueryItem("url", url)]))
    }

    private struct AddBody: Encodable, Sendable {
        let name: String?
        let url: String
    }
}

extension Node64.DNS64.Upstreams {
    /// Upstream servers (DNS-over-HTTPS/TLS/QUIC) with statistics, the mode and the router for local names.
    ///
    /// `GET /dns64/upstreams`
    public func list() async throws -> Node64.DNS64Upstreams {
        try await client.send(Request(.get, "/dns64/upstreams"))
    }

    /// Adds a custom upstream server (enabled). Answers `400` if invalid or already present.
    ///
    /// - Parameters:
    ///   - url: `https://…` (DoH), `tls://name[:853]` (DoT) or `quic://name[:853]` (DoQ).
    ///   - name: Display name.
    ///   - ips: Bootstrap IP addresses.
    /// - Returns: The new settings.
    ///
    /// `POST /dns64/upstreams`
    @discardableResult
    public func add(_ url: String, name: String? = nil, ips: [String]? = nil) async throws -> Node64.DNS64Settings {
        try await client.send(Request(.post, "/dns64/upstreams", body: .json(AddBody(name: name, url: url, ips: ips))))
    }

    /// Removes a custom upstream server. Answers `404` if there is no custom server with this URL.
    ///
    /// - Returns: The new settings.
    ///
    /// `DELETE /dns64/upstreams`
    @discardableResult
    public func remove(_ url: String) async throws -> Node64.DNS64Settings {
        try await client.send(Request(.delete, "/dns64/upstreams", query: [QueryItem("url", url)]))
    }

    private struct AddBody: Encodable, Sendable {
        let name: String?
        let url: String
        let ips: [String]?
    }
}

extension Node64.DNS64.Cache {
    /// Cache counters since start.
    ///
    /// `GET /dns64/cache`
    public func get() async throws -> Node64.DNS64Cache {
        try await client.send(Request(.get, "/dns64/cache"))
    }

    /// Empties the cache.
    ///
    /// - Returns: The number of entries removed (`flushed`).
    ///
    /// `POST /dns64/cache/flush`
    @discardableResult
    public func flush() async throws -> Node64.DNS64CacheFlushResult {
        try await client.send(Request(.post, "/dns64/cache/flush"))
    }
}

extension Node64.DNS64.Allowlist {
    /// Allowed domains (they apply to subdomains too).
    ///
    /// `GET /dns64/allowlist`
    public func list() async throws -> [Node64.DNS64AllowlistEntry] {
        try await client.send(Request(.get, "/dns64/allowlist"))
    }

    /// Allows a domain. Answers `400` for an invalid domain name.
    ///
    /// - Returns: The normalized domain.
    ///
    /// `POST /dns64/allowlist`
    @discardableResult
    public func add(_ domain: String) async throws -> Node64.DNS64AllowlistAdded {
        try await client.send(Request(.post, "/dns64/allowlist", body: .json(DomainBody(domain: domain))))
    }

    /// Removes an allowed domain. Answers `400` for an invalid domain name.
    ///
    /// `DELETE /dns64/allowlist`
    public func remove(_ domain: String) async throws {
        try await client.sendWithoutContent(Request(.delete, "/dns64/allowlist", query: [QueryItem("domain", domain)]))
    }

    /// Allows many domains at once, one per entry. Comments (`#`) and timestamps after the domain are
    /// ignored; existing entries stay.
    ///
    /// `POST /dns64/allowlist/import`
    @discardableResult
    public func importDomains(_ domains: [String]) async throws -> Node64.DNS64AllowlistImportResult {
        try await client.send(Request(.post, "/dns64/allowlist/import", body: .json(ImportBody(domains: domains))))
    }

    private struct DomainBody: Encodable, Sendable {
        let domain: String
    }

    private struct ImportBody: Encodable, Sendable {
        let domains: [String]
    }
}
