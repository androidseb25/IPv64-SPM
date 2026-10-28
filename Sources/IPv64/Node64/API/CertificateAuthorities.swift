import Foundation

extension Node64.Certificates {
    /// Own certificate authorities (schema `CA`).
    public var authorities: Authorities { Authorities(client: client) }

    /// Endpoints of the own CAs (`/cas`).
    public struct Authorities: Sendable {
        let client: Node64

        /// Own CAs.
        ///
        /// `GET /cas`
        public func list() async throws -> [Node64.CertificateAuthority] {
            try await client.send(Request(.get, "/cas"))
        }

        /// Creates an own CA (valid for 10 years).
        ///
        /// - Parameters:
        ///   - name: Name.
        ///   - keyType: Key type; the server default is ECDSA.
        ///   - constrained: Only private names (`*.lan`, `*.home.arpa`, `*.internal` …) and private IPs; the server default is `true`.
        ///   - domains: Additionally permitted domains.
        ///
        /// `POST /cas`
        public func create(
            name: String,
            keyType: Node64.CertificateKeyType? = nil,
            constrained: Bool? = nil,
            domains: [String]? = nil
        ) async throws -> Node64.CertificateAuthority {
            try await client.send(Request(.post, "/cas", body: .json(CreateBody(
                name: name, keyType: keyType, constrained: constrained, domains: domains
            ))))
        }

        /// Imports an existing CA (also an intermediate CA with chain).
        ///
        /// The input contains the private key and password: treat it as a secret.
        /// Fails with 422 if it is no CA certificate, the key does not match or the CA exists.
        ///
        /// `POST /cas/import`
        public func importCA(_ input: Node64.CertificateAuthorityImportInput) async throws -> Node64.CertificateAuthority {
            try await client.send(Request(.post, "/cas/import", body: .json(input)))
        }

        /// One CA.
        ///
        /// `GET /cas/{id}`
        public func get(_ id: Int) async throws -> Node64.CertificateAuthority {
            try await client.send(Request(.get, "/cas/\(id)"))
        }

        /// Renames a CA.
        ///
        /// `PUT /cas/{id}`
        public func rename(_ id: Int, to name: String) async throws -> Node64.CertificateAuthority {
            try await client.send(Request(.put, "/cas/\(id)", body: .json(RenameBody(name: name))))
        }

        /// Deletes a CA. Only possible without issued certificates (otherwise 409).
        ///
        /// `DELETE /cas/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/cas/\(id)"))
        }

        /// CA certificate to install on devices.
        ///
        /// - Parameter format: `pem` (server default), `crt` (DER, Windows/Android) or `mobileconfig` (iOS/macOS).
        ///
        /// `GET /cas/{id}/file`
        public func file(_ id: Int, format: Node64.CertificateAuthorityFileFormat? = nil) async throws -> Data {
            try await client.sendData(
                Request(.get, "/cas/\(id)/file", query: [QueryItem("format", format)]),
                accept: "application/x-pem-file, application/x-x509-ca-cert, application/x-apple-aspen-config, */*"
            )
        }

        private struct CreateBody: Encodable, Sendable {
            let name: String
            let keyType: Node64.CertificateKeyType?
            let constrained: Bool?
            let domains: [String]?

            enum CodingKeys: String, CodingKey {
                case name
                case keyType = "key_type"
                case constrained, domains
            }
        }

        private struct RenameBody: Encodable, Sendable {
            let name: String
        }
    }

    /// Additional ACME authorities besides Let's Encrypt (schema `ACMECA`).
    public var acmeAuthorities: ACMEAuthorities { ACMEAuthorities(client: client) }

    /// Endpoints of the additional ACME authorities (`/acme-cas`).
    public struct ACMEAuthorities: Sendable {
        let client: Node64

        /// Additional ACME authorities.
        ///
        /// `GET /acme-cas`
        public func list() async throws -> [Node64.ACMEAuthority] {
            try await client.send(Request(.get, "/acme-cas"))
        }

        /// Adds an ACME authority (ZeroSSL, Google, SSL.com, step-ca …).
        ///
        /// The directory is queried. If the authority requires External Account Binding,
        /// `eabKID` and `eabHMAC` are required. `eabHMAC` is a secret.
        ///
        /// - Parameters:
        ///   - name: Name.
        ///   - directory: ACME directory URL.
        ///   - acceptTOS: Accept the authority's terms of service.
        ///   - eabKID: EAB key ID.
        ///   - eabHMAC: EAB HMAC key (Base64).
        ///   - rootPEM: Root certificate of the authority, e.g. for step-ca.
        ///
        /// `POST /acme-cas`
        public func create(
            name: String,
            directory: String,
            acceptTOS: Bool,
            eabKID: String? = nil,
            eabHMAC: String? = nil,
            rootPEM: String? = nil
        ) async throws -> Node64.ACMEAuthority {
            try await client.send(Request(.post, "/acme-cas", body: .json(AddBody(
                name: name, directory: directory, eabKID: eabKID, eabHMAC: eabHMAC, rootPEM: rootPEM, acceptTOS: acceptTOS
            ))))
        }

        /// Templates of well-known authorities. The spec describes the items only as objects.
        ///
        /// `GET /acme-cas/presets`
        public func presets() async throws -> [JSONValue] {
            try await client.send(Request(.get, "/acme-cas/presets"))
        }

        /// Removes an ACME authority. Only possible without certificates (otherwise 409).
        ///
        /// `DELETE /acme-cas/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/acme-cas/\(id)"))
        }

        private struct AddBody: Encodable, Sendable {
            let name: String
            let directory: String
            let eabKID: String?
            let eabHMAC: String?
            let rootPEM: String?
            let acceptTOS: Bool

            enum CodingKeys: String, CodingKey {
                case name, directory
                case eabKID = "eab_kid"
                case eabHMAC = "eab_hmac"
                case rootPEM = "root_pem"
                case acceptTOS = "accept_tos"
            }
        }
    }
}
