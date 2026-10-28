import Foundation

extension IPv64 {
    /// CDN: reverse proxy and port mapping for your domains.
    ///
    /// Most changes respond with `202 Accepted` and the new state. A change is complete
    /// once ``CDNDomain/pending`` is empty; poll ``get(_:)`` until then.
    public var cdn: CDN { CDN(client: self) }

    /// Endpoints of the *CDN* area.
    public struct CDN: Sendable {
        let client: IPv64

        /// Lists all CDN domains.
        ///
        /// `GET /cdn`
        public func list() async throws -> [CDNDomain] {
            try await client.send(Request(.get, "/cdn"))
        }

        /// Adds a domain to the CDN. A CDN server is assigned automatically afterwards.
        ///
        /// - Parameter domain: Domain ID or name.
        ///
        /// `POST /cdn`
        public func add(domain: String) async throws -> CDNDomainDetail {
            try await client.send(Request(.post, "/cdn", body: .json(AddBody(domain: domain))))
        }

        /// A CDN domain including its port mappings.
        ///
        /// - Parameter token: CDN token or ID (32 characters).
        ///
        /// `GET /cdn/{token}`
        public func get(_ token: String) async throws -> CDNDomainDetail {
            try await client.send(Request(.get, "/cdn/\(token)"))
        }

        /// Changes the proxy settings. Only the passed fields are changed. HTTPS in the
        /// frontend automatically requests a Let's Encrypt certificate.
        ///
        /// - Parameters:
        ///   - token: CDN token or ID.
        ///   - frontend: Frontend mode.
        ///   - backendScheme: Protocol to your server.
        ///   - backendPort: Port of your server (1 to 65535).
        ///   - websocket: WebSocket support, only with an active proxy.
        ///   - caching: Cache settings.
        ///   - accessList: Access list settings.
        ///
        /// `PATCH /cdn/{token}`
        public func update(
            _ token: String,
            frontend: CDNFrontend? = nil,
            backendScheme: CDNBackendScheme? = nil,
            backendPort: Int? = nil,
            websocket: Bool? = nil,
            caching: CDNCachingSettings? = nil,
            accessList: CDNAccessListSettings? = nil
        ) async throws -> CDNDomainDetail {
            let body = UpdateBody(
                frontend: frontend,
                backendScheme: backendScheme,
                backendPort: backendPort,
                websocket: websocket,
                caching: caching,
                accessList: accessList
            )
            return try await client.send(Request(.patch, "/cdn/\(token)", body: .json(body)))
        }

        /// Removes a domain from the CDN. Turn the CDN off for all records first.
        ///
        /// Responds with `202 Accepted`; the removal is complete once the domain disappears
        /// (``CDNPendingTask/deletion`` is pending until then).
        ///
        /// `DELETE /cdn/{token}`
        public func delete(_ token: String) async throws -> CDNDomain {
            try await client.send(Request(.delete, "/cdn/\(token)"))
        }

        /// Turns the reverse proxy on. At least one record must run through the CDN.
        ///
        /// Responds with `202 Accepted`; done once ``CDNDomain/pending`` is empty.
        ///
        /// `POST /cdn/{token}/proxy/enable`
        public func enableProxy(_ token: String) async throws -> CDNDomain {
            try await client.send(Request(.post, "/cdn/\(token)/proxy/enable"))
        }

        /// Turns the reverse proxy off.
        ///
        /// Responds with `202 Accepted`; done once ``CDNDomain/pending`` is empty.
        ///
        /// `POST /cdn/{token}/proxy/disable`
        public func disableProxy(_ token: String) async throws -> CDNDomain {
            try await client.send(Request(.post, "/cdn/\(token)/proxy/disable"))
        }

        /// Turns the portmapper on. At least one record must run through the CDN.
        ///
        /// Responds with `202 Accepted`; done once ``CDNDomain/pending`` is empty.
        ///
        /// `POST /cdn/{token}/portmapper/enable`
        public func enablePortmapper(_ token: String) async throws -> CDNDomain {
            try await client.send(Request(.post, "/cdn/\(token)/portmapper/enable"))
        }

        /// Turns the portmapper off.
        ///
        /// Responds with `202 Accepted`; done once ``CDNDomain/pending`` is empty.
        ///
        /// `POST /cdn/{token}/portmapper/disable`
        public func disablePortmapper(_ token: String) async throws -> CDNDomain {
            try await client.send(Request(.post, "/cdn/\(token)/portmapper/disable"))
        }

        /// Redeploys the configuration.
        ///
        /// Responds with `202 Accepted`; done once ``CDNDomain/pending`` is empty.
        ///
        /// `POST /cdn/{token}/redeploy`
        public func redeploy(_ token: String) async throws -> CDNDomain {
            try await client.send(Request(.post, "/cdn/\(token)/redeploy"))
        }

        /// Resets the traffic counters of the domain.
        ///
        /// `POST /cdn/{token}/reset-traffic`
        public func resetTraffic(_ token: String) async throws -> CDNDomain {
            try await client.send(Request(.post, "/cdn/\(token)/reset-traffic"))
        }

        /// Moves the domain to another CDN server.
        ///
        /// Responds with `202 Accepted`; done once ``CDNDomain/pending`` is empty.
        ///
        /// `POST /cdn/{token}/move`
        public func move(_ token: String) async throws -> CDNDomain {
            try await client.send(Request(.post, "/cdn/\(token)/move"))
        }

        /// Reissues the certificate. Only with an active proxy and an HTTPS frontend.
        ///
        /// Responds with `202 Accepted`; done once ``CDNDomain/pending`` is empty.
        ///
        /// `POST /cdn/{token}/renew-certificate`
        public func renewCertificate(_ token: String) async throws -> CDNDomain {
            try await client.send(Request(.post, "/cdn/\(token)/renew-certificate"))
        }

        private struct AddBody: Encodable, Sendable {
            let domain: String
        }

        private struct UpdateBody: Encodable, Sendable {
            let frontend: CDNFrontend?
            let backendScheme: CDNBackendScheme?
            let backendPort: Int?
            let websocket: Bool?
            let caching: CDNCachingSettings?
            let accessList: CDNAccessListSettings?

            enum CodingKeys: String, CodingKey {
                case frontend
                case backendScheme = "backend_scheme"
                case backendPort = "backend_port"
                case websocket, caching
                case accessList = "access_list"
            }
        }
    }
}

// MARK: - Records

extension IPv64.CDN {
    /// A- and AAAA-records of a CDN domain.
    public var records: Records { Records(client: client) }

    /// CDN state of the records of a domain.
    public struct Records: Sendable {
        let client: IPv64

        /// A- and AAAA-records of the domain with their CDN state.
        ///
        /// - Parameter cdn: CDN token or ID.
        ///
        /// `GET /cdn/{token}/records`
        public func list(cdn token: String) async throws -> [Record] {
            try await client.send(Request(.get, "/cdn/\(token)/records"))
        }

        /// Routes a record through the CDN.
        ///
        /// Responds with `202 Accepted` and the updated record. `otherFamilyOnly` is only
        /// possible if the record is the only one on its prefix.
        ///
        /// - Parameters:
        ///   - record: Record ID or record token.
        ///   - cdn: CDN token or ID.
        ///   - mode: `full` (default on the server) or `otherFamilyOnly`.
        ///
        /// `POST /cdn/{token}/records/{record}/enable`
        public func enable(_ record: String, cdn token: String, mode: CDNRecordMode? = nil) async throws -> Record {
            let body = mode.map { RequestBody.json(EnableBody(mode: $0)) }
            return try await client.send(Request(.post, "/cdn/\(token)/records/\(record)/enable", body: body))
        }

        /// Serves a record directly again.
        ///
        /// Responds with `202 Accepted` and the updated record.
        ///
        /// - Parameters:
        ///   - record: Record ID or record token.
        ///   - cdn: CDN token or ID.
        ///
        /// `POST /cdn/{token}/records/{record}/disable`
        public func disable(_ record: String, cdn token: String) async throws -> Record {
            try await client.send(Request(.post, "/cdn/\(token)/records/\(record)/disable"))
        }

        private struct EnableBody: Encodable, Sendable {
            let mode: CDNRecordMode
        }
    }
}

// MARK: - Mappings

extension IPv64.CDN {
    /// Port mappings of a CDN domain.
    public var mappings: Mappings { Mappings(client: client) }

    /// Port mappings of a CDN domain.
    public struct Mappings: Sendable {
        let client: IPv64

        /// Lists the port mappings.
        ///
        /// - Parameter cdn: CDN token or ID.
        ///
        /// `GET /cdn/{token}/mappings`
        public func list(cdn token: String) async throws -> [CDNMapping] {
            try await client.send(Request(.get, "/cdn/\(token)/mappings"))
        }

        /// Creates a port mapping that forwards a public port of the CDN server to a port on
        /// your server. Without `listenPort` a free port between 50000 and 62000 is assigned.
        /// A and AAAA of the same name with the same target port use the same port.
        ///
        /// - Parameters:
        ///   - cdn: CDN token or ID.
        ///   - record: Record ID or token running through the CDN.
        ///   - targetPort: Port on your server (1 to 65535).
        ///   - transport: Protocol.
        ///   - name: Name.
        ///   - listenPort: Preferred public port (50000 to 62000).
        ///
        /// `POST /cdn/{token}/mappings`
        public func create(
            cdn token: String,
            record: String,
            targetPort: Int,
            transport: CDNTransport? = nil,
            name: String? = nil,
            listenPort: Int? = nil
        ) async throws -> CDNMapping {
            let body = CreateBody(
                record: record,
                targetPort: targetPort,
                transport: transport,
                name: name,
                listenPort: listenPort
            )
            return try await client.send(Request(.post, "/cdn/\(token)/mappings", body: .json(body)))
        }

        /// Deletes a port mapping.
        ///
        /// - Parameters:
        ///   - mapping: Mapping ID.
        ///   - cdn: CDN token or ID.
        ///
        /// `DELETE /cdn/{token}/mappings/{mapping}`
        public func delete(_ mapping: String, cdn token: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/cdn/\(token)/mappings/\(mapping)"))
        }

        private struct CreateBody: Encodable, Sendable {
            let record: String
            let targetPort: Int
            let transport: CDNTransport?
            let name: String?
            let listenPort: Int?

            enum CodingKeys: String, CodingKey {
                case record
                case targetPort = "target_port"
                case transport, name
                case listenPort = "listen_port"
            }
        }
    }
}

// MARK: - Access list

extension IPv64.CDN {
    /// Access list of a CDN domain.
    public var accessList: AccessList { AccessList(client: client) }

    /// Access list of a CDN domain. Whether it allows or blocks is set in
    /// ``CDNDomain/Proxy/AccessList/mode``.
    public struct AccessList: Sendable {
        let client: IPv64

        /// Lists the access list entries.
        ///
        /// - Parameter cdn: CDN token or ID.
        ///
        /// `GET /cdn/{token}/access-list`
        public func list(cdn token: String) async throws -> [AccessListEntry] {
            try await client.send(Request(.get, "/cdn/\(token)/access-list"))
        }

        /// Adds an entry.
        ///
        /// - Parameters:
        ///   - cdn: CDN token or ID.
        ///   - address: IP address or network in CIDR notation.
        ///
        /// `POST /cdn/{token}/access-list`
        public func add(cdn token: String, address: String) async throws -> AccessListEntry {
            try await client.send(Request(.post, "/cdn/\(token)/access-list", body: .json(AddBody(address: address))))
        }

        /// Removes an entry.
        ///
        /// - Parameters:
        ///   - id: Entry ID.
        ///   - cdn: CDN token or ID.
        ///
        /// `DELETE /cdn/{token}/access-list/{id}`
        public func delete(_ id: Int, cdn token: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/cdn/\(token)/access-list/\(id)"))
        }

        private struct AddBody: Encodable, Sendable {
            let address: String
        }
    }
}
