import Foundation

extension Node64.Certificates {
    /// Certificates without private keys, expiring soonest first.
    ///
    /// `GET /certs`
    public func list() async throws -> [Node64.Certificate] {
        try await client.send(Request(.get, "/certs"))
    }

    /// Requests a certificate or issues one with an own CA; it is fetched in the background.
    ///
    /// The returned certificate is usually `pending`; poll ``get(_:)`` until
    /// ``Node64/Certificate/status`` is no longer `pending`. Accept the terms first
    /// (``Account/update(email:acceptTOS:)``). Fails with 409 if the terms are not accepted
    /// or no ipv64 API key is set, and with 422 for invalid names, source or alias target.
    ///
    /// `POST /certs`
    public func create(_ input: Node64.CertificateCreateInput) async throws -> Node64.Certificate {
        try await client.send(Request(.post, "/certs", body: .json(input)))
    }

    /// Uploads an own certificate as JSON (PEM `cert` and `key`, or `p12`). At most 1 MB.
    ///
    /// The input contains the private key and password: treat it as a secret. A wrong or
    /// missing password fails with 422 and `field=password`.
    ///
    /// `POST /certs/upload`
    public func upload(_ input: Node64.CertificateUploadInput) async throws -> Node64.Certificate {
        try await client.send(Request(.post, "/certs/upload", body: .json(input)))
    }

    /// Uploads an own certificate as `multipart/form-data`.
    ///
    /// - Parameters:
    ///   - certFile: PEM, or a `.pfx`/`.p12` file.
    ///   - keyFile: PEM key file (not needed for PKCS#12).
    ///   - keyPassword: Password of the encrypted key or PKCS#12 file; not stored by the node.
    ///
    /// Treat the key and password as secrets. At most 1 MB.
    ///
    /// `POST /certs/upload`
    public func upload(certFile: Data, keyFile: Data? = nil, keyPassword: String? = nil) async throws -> Node64.Certificate {
        var form = MultipartFormData()
        form.append(certFile, name: "cert_file", filename: "cert.pem", contentType: "application/octet-stream")
        if let keyFile {
            form.append(keyFile, name: "key_file", filename: "key.pem", contentType: "application/octet-stream")
        }
        if let keyPassword {
            form.append(keyPassword, name: "key_password")
        }
        return try await client.send(Request(.post, "/certs/upload", body: .multipart(form)))
    }

    /// ipv64 domains of the account (for DNS-01 and as alias targets).
    ///
    /// Fails with 409 if no ipv64 API key is set.
    ///
    /// `GET /certs/domains`
    public func domains() async throws -> [String] {
        try await client.send(Request(.get, "/certs/domains"))
    }

    /// One certificate.
    ///
    /// `GET /certs/{id}`
    public func get(_ id: Int) async throws -> Node64.Certificate {
        try await client.send(Request(.get, "/certs/\(id)"))
    }

    /// Switches automatic renewal. Fails with 409 for uploaded certificates.
    ///
    /// `PUT /certs/{id}`
    public func update(_ id: Int, autoRenew: Bool) async throws -> Node64.Certificate {
        try await client.send(Request(.put, "/certs/\(id)", body: .json(AutoRenewBody(autoRenew: autoRenew))))
    }

    /// Deletes a certificate.
    ///
    /// - Parameter force: Delete even if it is in use (`force=1`).
    ///
    /// Fails with 409 if the certificate is in use (without `force`) or being fetched.
    ///
    /// `DELETE /certs/{id}`
    public func delete(_ id: Int, force: Bool = false) async throws {
        try await client.sendWithoutContent(Request(
            .delete, "/certs/\(id)",
            query: [QueryItem("force", force ? "1" : nil)]
        ))
    }

    /// Renews a Let's Encrypt certificate now; it is fetched in the background.
    ///
    /// Fails with 409 if a run is in progress, the certificate was uploaded, or the terms are missing.
    ///
    /// `POST /certs/{id}/renew`
    public func renew(_ id: Int) async throws -> Node64.Certificate {
        try await client.send(Request(.post, "/certs/\(id)/renew"))
    }

    /// Certificate with chain as PEM text, without the private key.
    ///
    /// Fails with 404 if unknown or not fetched yet.
    ///
    /// `GET /certs/{id}/chain`
    public func chain(_ id: Int) async throws -> String {
        try await client.sendText(Request(.get, "/certs/\(id)/chain"), accept: "application/pem-certificate-chain")
    }

    /// Details of the issued certificate (valid until, fingerprint) for scripts.
    ///
    /// The `ETag` response header equals ``Node64/CertMeta/fingerprintSHA256``. Fails with 409
    /// if the certificate is not issued yet.
    ///
    /// `GET /certs/{id}/meta`
    public func meta(_ id: Int) async throws -> Node64.CertMeta {
        try await client.send(Request(.get, "/certs/\(id)/meta"))
    }

    /// Downloads the certificate as a file.
    ///
    /// The formats `key`, `pem` and `zip` contain the private key and are recorded in the audit log:
    /// treat the result as a secret. For polling use ``bundle(_:format:ifNoneMatch:)``.
    ///
    /// - Parameter format: File format; the server default is `zip`.
    ///
    /// `GET /certs/{id}/bundle`
    public func bundle(_ id: Int, format: Node64.CertificateBundleFormat? = nil) async throws -> Data {
        try await client.sendData(
            Request(.get, "/certs/\(id)/bundle", query: [QueryItem("format", format)]),
            accept: Self.bundleAccept
        )
    }

    /// Downloads the certificate only if it changed.
    ///
    /// Sends `If-None-Match` and returns ``Node64/CertificateBundleResult/notModified`` on HTTP 304.
    /// The formats `key`, `pem` and `zip` contain the private key: treat the result as a secret.
    ///
    /// - Parameters:
    ///   - format: File format; the server default is `zip`.
    ///   - etag: ETag (fingerprint) of an earlier download.
    ///
    /// `GET /certs/{id}/bundle`
    public func bundle(
        _ id: Int,
        format: Node64.CertificateBundleFormat? = nil,
        ifNoneMatch etag: String
    ) async throws -> Node64.CertificateBundleResult {
        var request = Request(
            .get, "/certs/\(id)/bundle",
            query: [QueryItem("format", format)],
            headers: ["If-None-Match": etag]
        )
        request.accept = Self.bundleAccept
        let (data, response) = try await client.perform(request)
        if response.statusCode == 304 {
            return .notModified
        }
        return .changed(data, etag: response.value(forHTTPHeaderField: "ETag"))
    }

    /// PKCS#12 file (`.p12`) protected by a password, for Windows, NAS and routers.
    ///
    /// The result contains the private key and is recorded in the audit log: treat it as a secret.
    ///
    /// - Parameters:
    ///   - password: 4 to 128 characters.
    ///   - legacy: Old 3DES encryption for older devices; otherwise AES-256.
    ///
    /// `POST /certs/{id}/p12`
    public func p12(_ id: Int, password: String, legacy: Bool = false) async throws -> Data {
        try await client.sendData(
            Request(.post, "/certs/\(id)/p12", body: .json(P12Body(password: password, legacy: legacy))),
            accept: "application/x-pkcs12"
        )
    }

    /// DNS providers with their fields.
    ///
    /// `GET /certs/dns-providers`
    public func dnsProviders() async throws -> [Node64.DNSProvider] {
        try await client.send(Request(.get, "/certs/dns-providers"))
    }

    private static let bundleAccept = "application/zip, application/x-pem-file, application/pem-certificate-chain"

    private struct AutoRenewBody: Encodable, Sendable {
        let autoRenew: Bool

        enum CodingKeys: String, CodingKey {
            case autoRenew = "auto_renew"
        }
    }

    private struct P12Body: Encodable, Sendable {
        let password: String
        let legacy: Bool
    }
}

extension Node64.Certificates {
    /// ACME account (email and terms of service).
    public var account: Account { Account(client: client) }

    /// Endpoints of the ACME account.
    public struct Account: Sendable {
        let client: Node64

        /// ACME account: email and terms of service.
        ///
        /// `GET /certs/account`
        public func get() async throws -> Node64.CertAccount {
            try await client.send(Request(.get, "/certs/account"))
        }

        /// Sets the email and accepts the Let's Encrypt terms of service. Fields left `nil` are not sent.
        ///
        /// An invalid email fails with 422.
        ///
        /// `PUT /certs/account`
        public func update(email: String? = nil, acceptTOS: Bool? = nil) async throws -> Node64.CertAccount {
            try await client.send(Request(.put, "/certs/account", body: .json(Body(email: email, acceptTOS: acceptTOS))))
        }

        private struct Body: Encodable, Sendable {
            let email: String?
            let acceptTOS: Bool?

            enum CodingKeys: String, CodingKey {
                case email
                case acceptTOS = "accept_tos"
            }
        }
    }

    /// DNS accounts for DNS-01 validation with other providers.
    public var dnsAccounts: DNSAccounts { DNSAccounts(client: client) }

    /// Endpoints of the DNS accounts.
    public struct DNSAccounts: Sendable {
        let client: Node64

        /// DNS accounts without secret values.
        ///
        /// `GET /certs/dns-accounts`
        public func list() async throws -> [Node64.DNSAccount] {
            try await client.send(Request(.get, "/certs/dns-accounts"))
        }

        /// Creates a DNS account.
        ///
        /// - Parameters:
        ///   - name: Name.
        ///   - provider: Provider ID from ``Node64/Certificates/dnsProviders()``.
        ///   - values: Provider fields; they may contain secrets.
        ///
        /// An unknown provider or missing fields fail with 422.
        ///
        /// `POST /certs/dns-accounts`
        public func create(name: String, provider: String, values: [String: String]) async throws -> Node64.DNSAccount {
            try await client.send(Request(.post, "/certs/dns-accounts", body: .json(Body(name: name, provider: provider, values: values))))
        }

        /// Changes a DNS account. Empty secret fields keep their value; the provider cannot change.
        ///
        /// `PUT /certs/dns-accounts/{id}`
        public func update(_ id: Int, name: String? = nil, values: [String: String]? = nil) async throws -> Node64.DNSAccount {
            try await client.send(Request(.put, "/certs/dns-accounts/\(id)", body: .json(Body(name: name, provider: nil, values: values))))
        }

        /// Deletes a DNS account. Fails with 409 if a certificate uses it.
        ///
        /// `DELETE /certs/dns-accounts/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/certs/dns-accounts/\(id)"))
        }

        private struct Body: Encodable, Sendable {
            let name: String?
            let provider: String?
            let values: [String: String]?
        }
    }
}
