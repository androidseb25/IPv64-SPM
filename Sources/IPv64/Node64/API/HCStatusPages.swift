import Foundation

extension Node64.HC {
    /// Public status pages, their notices and logos.
    public var statusPages: StatusPages { StatusPages(client: client) }

    /// Endpoints of the status pages (tag *Healthchecks*).
    public struct StatusPages: Sendable { let client: Node64 }
}

extension Node64.HC.StatusPages {
    /// Lists all status pages with groups and entries.
    ///
    /// The password is never returned, only `hasPassword`.
    ///
    /// `GET /status-pages`
    public func list() async throws -> [Node64.StatusPage] {
        try await client.send(Request(.get, "/status-pages"))
    }

    /// Creates a status page.
    ///
    /// Missing fields get defaults (layout `list`, theme `auto`, 90 days, refresh 60 s;
    /// publish on the node, uptime, history, noindex and powered-by on; `enabled` and
    /// `hcGroups` off). Without a slug it is derived from the title. `password` is plain text
    /// (4 to 72 characters) and stored as a bcrypt hash. A taken slug fails with 409.
    ///
    /// `POST /status-pages`
    public func create(_ input: Node64.StatusPageInput) async throws -> Node64.StatusPage {
        try await client.send(Request(.post, "/status-pages", body: .json(input)))
    }

    /// Creates a status page with just a title.
    ///
    /// `POST /status-pages`
    public func create(title: String) async throws -> Node64.StatusPage {
        try await create(Node64.StatusPageInput(title: title))
    }

    /// Reads a status page.
    ///
    /// `GET /status-pages/{id}`
    public func get(_ id: Int) async throws -> Node64.StatusPage {
        try await client.send(Request(.get, "/status-pages/\(id)"))
    }

    /// Changes a status page; only the fields you set change.
    ///
    /// `groups` replaces all groups and entries (their IDs change); without it they stay.
    /// `password` sets a new password, `"-"` removes it, empty or `nil` keeps it.
    ///
    /// `PUT /status-pages/{id}`
    public func update(_ id: Int, _ input: Node64.StatusPageInput) async throws -> Node64.StatusPage {
        try await client.send(Request(.put, "/status-pages/\(id)", body: .json(input)))
    }

    /// Deletes a status page with its groups, entries and notices.
    ///
    /// `DELETE /status-pages/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/status-pages/\(id)"))
    }

    /// Sets the logo of a status page.
    ///
    /// `data` is the image (PNG, JPEG, WebP or SVG, at most 256 KiB). The format is detected
    /// from the content; an `image/*` content type has to match it, `application/octet-stream`
    /// means detection by content only. Fails with 413 above 256 KiB and 415 for other formats.
    ///
    /// `PUT /status-pages/{id}/logo`
    public func setLogo(
        _ id: Int,
        data: Data,
        contentType: String = "application/octet-stream"
    ) async throws -> Node64.StatusPage {
        try await client.send(Request(.put, "/status-pages/\(id)/logo", body: .raw(data, contentType: contentType)))
    }

    /// Removes the logo of a status page.
    ///
    /// `DELETE /status-pages/{id}/logo`
    public func removeLogo(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/status-pages/\(id)/logo"))
    }
}

extension Node64.HC.StatusPages {
    /// Notices (announcements) of the status pages.
    public var notices: Notices { Notices(client: client) }

    /// Endpoints below `/status-pages/{id}/notices`.
    public struct Notices: Sendable { let client: Node64 }
}

extension Node64.HC.StatusPages.Notices {
    /// Lists the notices of a status page, open and resolved, newest first (at most 100), with their updates.
    ///
    /// - Parameter page: ID of the status page.
    ///
    /// `GET /status-pages/{id}/notices`
    public func list(page: Int) async throws -> [Node64.StatusNotice] {
        try await client.send(Request(.get, "/status-pages/\(page)/notices"))
    }

    /// Creates a notice on a status page. Fails with `422` when the title is missing or too long.
    ///
    /// - Parameters:
    ///   - page: ID of the status page.
    ///   - input: The notice.
    ///
    /// `POST /status-pages/{id}/notices`
    public func create(page: Int, _ input: Node64.StatusNoticeInput) async throws -> Node64.StatusNotice {
        try await client.send(Request(.post, "/status-pages/\(page)/notices", body: .json(input)))
    }

    /// Adds an update (text) to a notice, optionally changes its level and marks it resolved.
    ///
    /// - Parameters:
    ///   - id: ID of the notice.
    ///   - page: ID of the status page.
    ///   - input: The update.
    ///
    /// `PUT /status-pages/{id}/notices/{nid}`
    public func update(_ id: Int, page: Int, _ input: Node64.StatusNoticeUpdateInput) async throws -> Node64.StatusNotice {
        try await client.send(Request(.put, "/status-pages/\(page)/notices/\(id)", body: .json(input)))
    }

    /// Deletes a notice.
    ///
    /// - Parameters:
    ///   - id: ID of the notice.
    ///   - page: ID of the status page.
    ///
    /// `DELETE /status-pages/{id}/notices/{nid}`
    public func delete(_ id: Int, page: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/status-pages/\(page)/notices/\(id)"))
    }
}
