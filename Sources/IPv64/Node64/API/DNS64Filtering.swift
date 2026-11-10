import Foundation

extension Node64.DNS64 {
    /// Full top list with paging, search and sorting.
    ///
    /// - Parameters:
    ///   - kind: Which list.
    ///   - range: Time range (default `24h`).
    ///   - query: Part of the name (domain or client IP), sent as `q`.
    ///   - sort: Sort field (default `count`).
    ///   - direction: Sort direction (default descending, ascending for `name`), sent as `dir`.
    ///   - limit: Entries per page (default 50, maximum 500).
    ///   - offset: Entries to skip (default 0).
    ///
    /// `GET /dns64/top/list`
    public func topList(
        kind: Node64.DNS64TopKind,
        range: Node64.DNS64Range? = nil,
        query: String? = nil,
        sort: Node64.DNS64TopSort? = nil,
        direction: Node64.DNS64SortDirection? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) async throws -> Node64.DNS64TopPage {
        try await client.send(Request(.get, "/dns64/top/list", query: [
            QueryItem("kind", kind),
            QueryItem("range", range),
            QueryItem("q", query),
            QueryItem("sort", sort),
            QueryItem("dir", direction),
            QueryItem("limit", limit),
            QueryItem("offset", offset),
        ]))
    }

    /// Categories and services that can be blocked per click. Block a service by passing its
    /// ``Node64/DNS64Service/key`` (`svc:<id>`) in `categories` of a group rule or schedule.
    ///
    /// `GET /dns64/services`
    public func services() async throws -> Node64.DNS64Services {
        try await client.send(Request(.get, "/dns64/services"))
    }

    /// Entries from Docker labels (`node64.dns.name`) and the state of the sync. Turn the integration
    /// on with `docker` in ``updateSettings(_:)``.
    ///
    /// `GET /dns64/docker`
    public func docker() async throws -> Node64.DNS64Docker {
        try await client.send(Request(.get, "/dns64/docker"))
    }

    /// Allow lists: lists of domains that no blocklist blocks. Not to be confused with ``allowlist``
    /// (single allowed domains).
    public var allowLists: AllowLists { AllowLists(client: client) }
    /// Own deny list.
    public var denylist: Denylist { Denylist(client: client) }

    /// Allow list endpoints of DNS64 (`/dns64/allowlists`).
    public struct AllowLists: Sendable { let client: Node64 }
    /// Own deny list endpoints of DNS64.
    public struct Denylist: Sendable { let client: Node64 }
}

extension Node64.DNS64.AllowLists {
    /// Allow lists with number of rules, last update and error. They apply to all devices and groups;
    /// the own deny list takes precedence. Without a running DNS service only the settings are returned.
    ///
    /// `GET /dns64/allowlists`
    public func list() async throws -> [Node64.DNS64ListStatus] {
        try await client.send(Request(.get, "/dns64/allowlists"))
    }

    /// Adds an allow list (enabled). Formats: one domain per line, hosts or Adblock (`||example.com^`, `@@||example.com^`).
    /// Answers `400` if invalid or already present.
    ///
    /// - Returns: The new settings.
    ///
    /// `POST /dns64/allowlists`
    @discardableResult
    public func add(_ url: String, name: String? = nil) async throws -> Node64.DNS64Settings {
        try await client.send(Request(.post, "/dns64/allowlists", body: .json(AddBody(name: name, url: url, urls: nil))))
    }

    /// Adds several allow lists at once.
    ///
    /// Answers `422` if no list was added; that body has no error fields, so it is thrown as
    /// `Node64Error.httpStatus(code: 422, body:)` and the body decodes as ``Node64/DNS64ListsAddResult``.
    ///
    /// - Parameter urls: One URL per entry, optionally `Name | URL`.
    /// - Returns: The result per URL.
    ///
    /// `POST /dns64/allowlists`
    @discardableResult
    public func add(urls: [String]) async throws -> Node64.DNS64ListsAddResult {
        try await client.send(Request(.post, "/dns64/allowlists", body: .json(AddBody(name: nil, url: nil, urls: urls))))
    }

    /// Removes an allow list. Answers `404` if there is no list with this URL.
    ///
    /// - Returns: The new settings.
    ///
    /// `DELETE /dns64/allowlists`
    @discardableResult
    public func remove(_ url: String) async throws -> Node64.DNS64Settings {
        try await client.send(Request(.delete, "/dns64/allowlists", query: [QueryItem("url", url)]))
    }

    private struct AddBody: Encodable, Sendable {
        let name: String?
        let url: String?
        let urls: [String]?
    }
}

extension Node64.DNS64.Lists {
    /// Adds several custom blocklists at once.
    ///
    /// Answers `422` if no list was added; that body has no error fields, so it is thrown as
    /// `Node64Error.httpStatus(code: 422, body:)` and the body decodes as ``Node64/DNS64ListsAddResult``.
    ///
    /// - Parameter urls: One URL per entry, optionally `Name | URL`.
    /// - Returns: The result per URL.
    ///
    /// `POST /dns64/lists`
    @discardableResult
    public func add(urls: [String]) async throws -> Node64.DNS64ListsAddResult {
        try await client.send(Request(.post, "/dns64/lists", body: .json(UrlsBody(urls: urls))))
    }

    private struct UrlsBody: Encodable, Sendable {
        let urls: [String]
    }
}

extension Node64.DNS64.Denylist {
    /// The own deny list (every entry applies to subdomains too).
    ///
    /// `GET /dns64/denylist`
    public func list() async throws -> [Node64.DNS64DenylistEntry] {
        try await client.send(Request(.get, "/dns64/denylist"))
    }

    /// Blocks a domain. An identical allow entry is dropped. Answers `400` for an invalid domain
    /// name and `503` if the blocklist is not loaded.
    ///
    /// - Returns: The normalized domain.
    ///
    /// `POST /dns64/denylist`
    @discardableResult
    public func add(_ domain: String) async throws -> Node64.DNS64DenylistAdded {
        try await client.send(Request(.post, "/dns64/denylist", body: .json(DomainBody(domain: domain))))
    }

    /// Removes a blocked domain. Answers `400` for an invalid domain name.
    ///
    /// `DELETE /dns64/denylist`
    public func remove(_ domain: String) async throws {
        try await client.sendWithoutContent(Request(.delete, "/dns64/denylist", query: [QueryItem("domain", domain)]))
    }

    /// Replaces the whole deny list (`PUT`, full replace): entries not in `domains` are removed.
    /// `*.` prefixes and `#` comments are ignored; existing entries keep their date. If all entries
    /// are invalid the list stays unchanged and the node answers `422`, thrown as
    /// `Node64Error.httpStatus(code: 422, body:)`; the body decodes as ``Node64/DNS64DenylistReplaceResult``.
    ///
    /// - Parameter domains: One domain per entry.
    ///
    /// `PUT /dns64/denylist`
    @discardableResult
    public func replace(_ domains: [String]) async throws -> Node64.DNS64DenylistReplaceResult {
        try await client.send(Request(.put, "/dns64/denylist", body: .json(DomainsBody(domains: domains))))
    }

    private struct DomainBody: Encodable, Sendable {
        let domain: String
    }

    private struct DomainsBody: Encodable, Sendable {
        let domains: [String]
    }
}

extension Node64.DNS64.Zones {
    /// Shows the key for dynamic updates (TSIG) of a zone. Name and key are empty if dynamic updates
    /// were never turned on.
    ///
    /// The response contains **secret key material**; do not log or store it unprotected.
    ///
    /// `GET /dns64/zones/{id}/tsig`
    public func tsig(_ id: Int) async throws -> Node64.DNS64ZoneTSIG {
        try await client.send(Request(.get, "/dns64/zones/\(id)/tsig"))
    }

    /// Creates a new TSIG key and turns dynamic updates on. The old key stops working immediately.
    ///
    /// The response contains **secret key material**; do not log or store it unprotected.
    ///
    /// `POST /dns64/zones/{id}/tsig`
    public func regenerateTSIG(_ id: Int) async throws -> Node64.DNS64ZoneTSIG {
        try await client.send(Request(.post, "/dns64/zones/\(id)/tsig"))
    }
}
