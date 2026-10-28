import Foundation

extension Node64.DNS64.Records {
    /// Custom DNS records.
    ///
    /// `GET /dns64/records`
    public func list() async throws -> [Node64.DNS64Record] {
        try await client.send(Request(.get, "/dns64/records"))
    }

    /// Creates a custom record; it applies immediately.
    ///
    /// `*.name` matches all subnames, a CNAME must be the only record of its name, and A/AAAA records get
    /// a PTR record. Answers `400` if invalid or a duplicate.
    ///
    /// `POST /dns64/records`
    public func create(_ input: Node64.DNS64RecordInput) async throws -> Node64.DNS64Record {
        try await client.send(Request(.post, "/dns64/records", body: .json(input)))
    }

    /// Changes a custom record. The enabled state stays as it is.
    ///
    /// Sends the complete record (`name`, `type` and `value` are required); build `input` from the
    /// current record and change what you need.
    ///
    /// `PUT /dns64/records/{id}`
    public func update(_ id: Int, _ input: Node64.DNS64RecordInput) async throws -> Node64.DNS64Record {
        try await client.send(Request(.put, "/dns64/records/\(id)", body: .json(input)))
    }

    /// Deletes a custom record.
    ///
    /// `DELETE /dns64/records/{id}`
    public func delete(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.delete, "/dns64/records/\(id)"))
    }

    /// Turns a custom record on.
    ///
    /// `POST /dns64/records/{id}/enable`
    public func enable(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.post, "/dns64/records/\(id)/enable"))
    }

    /// Turns a custom record off.
    ///
    /// `POST /dns64/records/{id}/disable`
    public func disable(_ id: Int) async throws {
        try await client.sendWithoutContent(Request(.post, "/dns64/records/\(id)/disable"))
    }

    /// Imports records from a hosts file, CSV, JSON or a BIND zone file (sent as `text/plain`). Existing records stay.
    ///
    /// - Parameters:
    ///   - text: File content.
    ///   - zone: Zone for relative names of a zone file without `$ORIGIN`.
    ///
    /// `POST /dns64/records/import`
    @discardableResult
    public func importRecords(_ text: String, zone: String? = nil) async throws -> Node64.DNS64RecordImportResult {
        try await client.send(Request(
            .post, "/dns64/records/import",
            query: [QueryItem("zone", zone)],
            body: .raw(Data(text.utf8), contentType: "text/plain")
        ))
    }

    /// Exports custom records as a file.
    ///
    /// - Parameter format: `hosts` (A/AAAA only, default), `csv` or `json`.
    ///
    /// `GET /dns64/records/export`
    public func export(format: Node64.DNS64ExportFormat? = nil) async throws -> Data {
        try await client.sendData(
            Request(.get, "/dns64/records/export", query: [QueryItem("format", format)]),
            accept: "text/plain, text/csv, application/json"
        )
    }
}
