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
