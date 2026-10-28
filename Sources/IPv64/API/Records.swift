import Foundation

extension IPv64 {
    /// Manage DNS records.
    public var records: Records { Records(client: self) }

    /// Endpoints of the *DNS-Records* area.
    public struct Records: Sendable {
        let client: IPv64

        /// Lists the records of a domain.
        ///
        /// `GET /domains/{domain}/records`
        /// - Parameters:
        ///   - domain: Domain ID or full name.
        ///   - type: Only this record type.
        ///   - prefix: Only this prefix.
        public func list(domain: String, type: RecordType? = nil, prefix: String? = nil) async throws -> [Record] {
            try await client.send(Request(.get, "/domains/\(domain)/records", query: [
                QueryItem("type", type),
                QueryItem("prefix", prefix),
            ]))
        }

        /// Creates a record. The TTL is fixed at 60 seconds.
        ///
        /// Formats per type match the web interface, e.g. MX as `10 mail.example.com`.
        ///
        /// `POST /domains/{domain}/records`
        /// - Parameters:
        ///   - domain: Domain ID or full name.
        ///   - type: Record type.
        ///   - prefix: Prefix; empty or `@` means the domain itself.
        ///   - content: Record content.
        public func create(
            domain: String,
            type: RecordType,
            prefix: String? = nil,
            content: String
        ) async throws -> Record {
            try await client.send(Request(
                .post,
                "/domains/\(domain)/records",
                body: .json(CreateBody(type: type, prefix: prefix, content: content))
            ))
        }

        /// Deletes the record with exactly this type, prefix and content (handy for ACME clients).
        ///
        /// `DELETE /domains/{domain}/records`
        /// - Parameters:
        ///   - domain: Domain ID or full name.
        ///   - type: Record type.
        ///   - content: Record content.
        ///   - prefix: Prefix.
        public func delete(domain: String, type: RecordType, content: String, prefix: String? = nil) async throws {
            try await client.sendWithoutContent(Request(.delete, "/domains/\(domain)/records", query: [
                QueryItem("type", type),
                QueryItem("content", content),
                QueryItem("prefix", prefix),
            ]))
        }

        /// A single record.
        ///
        /// `GET /records/{record}`
        /// - Parameter record: Record ID or record token.
        public func get(_ record: String) async throws -> Record {
            try await client.send(Request(.get, "/records/\(record)"))
        }

        /// Changes a record.
        ///
        /// If only the IP of an A or AAAA record changes, ID and token are kept. Other changes replace the
        /// record, which then gets a new ID and token. Records managed by the CDN or DNS failover are locked.
        ///
        /// `PATCH /records/{record}`
        /// - Parameters:
        ///   - record: Record ID or record token.
        ///   - type: New type.
        ///   - prefix: New prefix.
        ///   - content: New content.
        public func update(
            _ record: String,
            type: RecordType? = nil,
            prefix: String? = nil,
            content: String? = nil
        ) async throws -> Record {
            try await client.send(Request(
                .patch,
                "/records/\(record)",
                body: .json(UpdateBody(type: type, prefix: prefix, content: content))
            ))
        }

        /// Deletes a record.
        ///
        /// `DELETE /records/{record}`
        /// - Parameter record: Record ID or record token.
        public func delete(_ record: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/records/\(record)"))
        }

        private struct CreateBody: Encodable, Sendable {
            let type: RecordType
            let prefix: String?
            let content: String
        }

        private struct UpdateBody: Encodable, Sendable {
            let type: RecordType?
            let prefix: String?
            let content: String?
        }
    }
}
