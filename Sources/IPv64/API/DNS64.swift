import Foundation

extension IPv64 {
    /// DNS64 clients: personal resolvers with filtering.
    ///
    /// Changes respond with `202 Accepted` and the new state. A change is complete once
    /// ``DNS64Client/state`` is `ready`; poll ``get(_:)`` until then.
    public var dns64: DNS64 { DNS64(client: self) }

    /// Endpoints of the *DNS64* area.
    public struct DNS64: Sendable {
        let client: IPv64

        /// Lists all DNS64 clients.
        ///
        /// `GET /dns64/clients`
        public func list() async throws -> [DNS64Client] {
            try await client.send(Request(.get, "/dns64/clients"))
        }

        /// Creates a client. Resolver addresses and ``DNS64Client/clientID`` are available
        /// once ``DNS64Client/state`` is `ready`.
        ///
        /// Responds with `202 Accepted` and the new client (state `applying`).
        ///
        /// - Parameter name: Name.
        ///
        /// `POST /dns64/clients`
        public func create(name: String? = nil) async throws -> DNS64Client {
            try await client.send(Request(.post, "/dns64/clients", body: .json(CreateBody(name: name))))
        }

        /// A client with rules, sources and DNS stamps.
        ///
        /// - Parameter token: Client token or ID (32 characters).
        ///
        /// `GET /dns64/clients/{token}`
        public func get(_ token: String) async throws -> DNS64Client {
            try await client.send(Request(.get, "/dns64/clients/\(token)"))
        }

        /// Changes a client. Only the passed fields are changed. The blocklists `adult` and
        /// `threats` are not part of the Free plan.
        ///
        /// May respond with `202 Accepted` (state `applying`) when a change is applied in the background.
        ///
        /// - Parameters:
        ///   - token: Client token or ID.
        ///   - name: Name.
        ///   - blockingEnabled: Filtering enabled.
        ///   - blocklists: Active blocklists.
        ///
        /// `PATCH /dns64/clients/{token}`
        public func update(
            _ token: String,
            name: String? = nil,
            blockingEnabled: Bool? = nil,
            blocklists: [DNS64Blocklist]? = nil
        ) async throws -> DNS64Client {
            let body = UpdateBody(name: name, blockingEnabled: blockingEnabled, blocklists: blocklists)
            return try await client.send(Request(.patch, "/dns64/clients/\(token)", body: .json(body)))
        }

        /// Deletes a client.
        ///
        /// Responds with `202 Accepted` and state `deleting`.
        ///
        /// `DELETE /dns64/clients/{token}`
        public func delete(_ token: String) async throws -> DNS64DeleteResult {
            try await client.send(Request(.delete, "/dns64/clients/\(token)"))
        }

        private struct CreateBody: Encodable, Sendable {
            let name: String?
        }

        private struct UpdateBody: Encodable, Sendable {
            let name: String?
            let blockingEnabled: Bool?
            let blocklists: [DNS64Blocklist]?

            enum CodingKeys: String, CodingKey {
                case name
                case blockingEnabled = "blocking_enabled"
                case blocklists
            }
        }
    }
}

// MARK: - Rules

extension IPv64.DNS64 {
    /// Allow and block rules of a client.
    public var rules: Rules { Rules(client: client) }

    /// Allow and block rules of a client.
    public struct Rules: Sendable {
        let client: IPv64

        /// Allows or blocks a domain.
        ///
        /// Responds with `202 Accepted` and the client (state `applying`).
        ///
        /// - Parameters:
        ///   - client: Client token or ID.
        ///   - domain: Domain.
        ///   - action: `allow` or `block`.
        ///
        /// `POST /dns64/clients/{token}/rules`
        public func create(
            client token: String,
            domain: String,
            action: DNS64RuleAction? = nil
        ) async throws -> DNS64Client {
            let body = CreateBody(domain: domain, action: action)
            return try await client.send(Request(.post, "/dns64/clients/\(token)/rules", body: .json(body)))
        }

        /// Removes a rule.
        ///
        /// - Parameters:
        ///   - id: Rule ID.
        ///   - client: Client token or ID.
        ///
        /// `DELETE /dns64/clients/{token}/rules/{id}`
        public func delete(_ id: Int, client token: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/dns64/clients/\(token)/rules/\(id)"))
        }

        private struct CreateBody: Encodable, Sendable {
            let domain: String
            let action: DNS64RuleAction?
        }
    }
}

// MARK: - Sources

extension IPv64.DNS64 {
    /// Source addresses of a client.
    public var sources: Sources { Sources(client: client) }

    /// Source addresses that assign requests on the shared resolver IPs to a client.
    public struct Sources: Sendable {
        let client: IPv64

        /// Adds a source address: either a fixed `ip` or an own A/AAAA `record` whose
        /// DynDNS address is followed. At most 5 per kind.
        ///
        /// Responds with `202 Accepted` and the client (state `applying`).
        ///
        /// - Parameters:
        ///   - client: Client token or ID.
        ///   - ip: Fixed IP address.
        ///   - record: Record ID or token.
        ///
        /// `POST /dns64/clients/{token}/sources`
        public func add(client token: String, ip: String? = nil, record: String? = nil) async throws -> DNS64Client {
            let body = AddBody(ip: ip, record: record)
            return try await client.send(Request(.post, "/dns64/clients/\(token)/sources", body: .json(body)))
        }

        /// Removes a source address.
        ///
        /// - Parameters:
        ///   - id: Numeric ID for fixed IPs, record token for records.
        ///   - client: Client token or ID.
        ///
        /// `DELETE /dns64/clients/{token}/sources/{id}`
        public func delete(_ id: String, client token: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/dns64/clients/\(token)/sources/\(id)"))
        }

        private struct AddBody: Encodable, Sendable {
            let ip: String?
            let record: String?
        }
    }
}
