import Foundation

extension IPv64 {
    /// Manage DynDNS and own domains.
    public var domains: Domains { Domains(client: self) }

    /// Endpoints of the *Domains* and *DynDNS* areas.
    public struct Domains: Sendable {
        let client: IPv64

        /// Lists all domains.
        ///
        /// `GET /domains`
        /// - Parameter kind: Only DynDNS or only own domains.
        public func list(kind: DomainKind? = nil) async throws -> [Domain] {
            try await client.send(Request(.get, "/domains", query: [QueryItem("kind", kind)]))
        }

        /// Creates a domain, respecting the limits of your plan.
        ///
        /// For a DynDNS domain use `<wish>.<zone>` (zones such as `ipv64.net`, `ipv64.de`, `any64.de`, ...).
        /// For an own domain set `own` to `true` and then enter the name servers
        /// `ns1.ipv64.net` and `ns2.ipv64.net` at your registrar.
        ///
        /// `POST /domains`
        /// - Parameters:
        ///   - name: Domain name, e.g. `meinname.ipv64.de`.
        ///   - own: Own domain instead of DynDNS.
        public func create(name: String, own: Bool? = nil) async throws -> DomainDetail {
            try await client.send(Request(.post, "/domains", body: .json(CreateBody(name: name, own: own))))
        }

        /// A domain including all its records.
        ///
        /// `GET /domains/{domain}`
        /// - Parameter domain: Domain ID or full name, e.g. `beispiel.ipv64.de`.
        public func get(_ domain: String) async throws -> DomainDetail {
            try await client.send(Request(.get, "/domains/\(domain)"))
        }

        /// Changes domain settings. Only the provided fields are changed.
        ///
        /// `PATCH /domains/{domain}`
        /// - Parameters:
        ///   - domain: Domain ID or full name.
        ///   - wildcard: Wildcard `*.name` on or off.
        ///   - ignore: Address family to ignore on DynDNS updates.
        ///   - ipv6Prefix: Fixed IPv6 prefix such as `2001:db8:1234:5600::/56`; an empty string turns it off.
        public func update(
            _ domain: String,
            wildcard: Bool? = nil,
            ignore: DomainIgnore? = nil,
            ipv6Prefix: String? = nil
        ) async throws -> DomainDetail {
            try await client.send(Request(
                .patch,
                "/domains/\(domain)",
                body: .json(UpdateBody(wildcard: wildcard, ignore: ignore, ipv6Prefix: ipv6Prefix))
            ))
        }

        /// Deletes the domain with all its records. Not possible while a DNS failover is active.
        ///
        /// `DELETE /domains/{domain}`
        /// - Parameter domain: Domain ID or full name.
        public func delete(_ domain: String) async throws {
            try await client.sendWithoutContent(Request(.delete, "/domains/\(domain)"))
        }

        /// Generates a new domain update token. The old token for `update.php` becomes invalid immediately.
        ///
        /// `POST /domains/{domain}/rotate-token`
        /// - Parameter domain: Domain ID or full name.
        public func rotateToken(_ domain: String) async throws -> Domain {
            try await client.send(Request(.post, "/domains/\(domain)/rotate-token"))
        }

        /// Resets the domain: deletes all active records and sets up the zone anew.
        ///
        /// `POST /domains/{domain}/reset`
        /// - Parameter domain: Domain ID or full name.
        public func reset(_ domain: String) async throws -> DomainDetail {
            try await client.send(Request(.post, "/domains/\(domain)/reset"))
        }

        /// Updates the A and AAAA records of a domain or prefix.
        ///
        /// Without `ipv4` and `ipv6` the sender address is used. Only public addresses are allowed.
        /// Missing records are created. The update counts in the statistics but is not limited by the daily limit.
        ///
        /// `POST /domains/{domain}/dyndns`
        /// - Parameters:
        ///   - domain: Domain ID or full name.
        ///   - ipv4: IPv4 address.
        ///   - ipv6: IPv6 address.
        ///   - prefix: Prefix; empty means the domain itself.
        public func updateDynDNS(
            _ domain: String,
            ipv4: String? = nil,
            ipv6: String? = nil,
            prefix: String? = nil
        ) async throws -> DynDNSResult {
            try await client.send(Request(
                .post,
                "/domains/\(domain)/dyndns",
                body: .json(DynDNSBody(ipv4: ipv4, ipv6: ipv6, prefix: prefix))
            ))
        }

        private struct CreateBody: Encodable, Sendable {
            let name: String
            let own: Bool?
        }

        private struct UpdateBody: Encodable, Sendable {
            let wildcard: Bool?
            let ignore: DomainIgnore?
            let ipv6Prefix: String?

            enum CodingKeys: String, CodingKey {
                case wildcard, ignore
                case ipv6Prefix = "ipv6_prefix"
            }
        }

        private struct DynDNSBody: Encodable, Sendable {
            let ipv4: String?
            let ipv6: String?
            let prefix: String?
        }
    }
}
