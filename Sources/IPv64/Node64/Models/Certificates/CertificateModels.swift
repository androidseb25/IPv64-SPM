import Foundation

extension Node64 {
    /// How a certificate is issued.
    public struct CertificateSource: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// All names are in the ipv64 account (DNS-01 via the central API key, wildcards allowed).
        public static let ipv64: Self = "ipv64"
        /// Foreign domain with a CNAME `_acme-challenge.<name>` to the alias target.
        public static let alias: Self = "alias"
        /// HTTP-01; port 80 must reach the node (no wildcards).
        public static let http: Self = "http"
        /// Other DNS provider through a DNS account.
        public static let dns: Self = "dns"
        /// Uploaded certificate.
        public static let upload: Self = "upload"
        /// Issued by an own CA.
        public static let ca: Self = "ca"
        /// Self-signed.
        public static let `self`: Self = "self"
    }

    /// Issuing state of a certificate.
    public struct CertificateStatus: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let pending: Self = "pending"
        public static let valid: Self = "valid"
        public static let error: Self = "error"
        public static let expired: Self = "expired"
    }

    /// Key type of a self-signed certificate or an own CA.
    public struct CertificateKeyType: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// ECDSA P-256.
        public static let ecdsa: Self = "ecdsa"
        /// RSA 2048.
        public static let rsa: Self = "rsa"
    }

    /// File format of ``Node64/Certificates/bundle(_:format:)``.
    public struct CertificateBundleFormat: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// ZIP with `fullchain.pem`, `cert.pem`, `chain.pem`, `privkey.pem` (contains the private key).
        public static let zip: Self = "zip"
        /// Certificate with chain.
        public static let fullchain: Self = "fullchain"
        /// Certificate only.
        public static let cert: Self = "cert"
        /// Chain only.
        public static let chain: Self = "chain"
        /// Private key only (secret).
        public static let key: Self = "key"
        /// Fullchain and private key in one file (secret).
        public static let pem: Self = "pem"
    }

    /// A certificate without its private key.
    ///
    /// Schema `Certificate`.
    public struct Certificate: Codable, Hashable, Sendable, Identifiable {
        /// Certificate ID.
        public let id: Int
        /// DNS names and IP addresses.
        public let names: [String]?
        /// How the certificate is issued.
        public let source: CertificateSource?
        /// Alias zone (source `alias`).
        public let aliasZone: String?
        /// Alias prefix (source `alias`).
        public let aliasPrefix: String?
        /// Issued by the Let's Encrypt test environment.
        public let staging: Bool?
        /// Renews automatically.
        public let autoRenew: Bool?
        /// Issuing state.
        public let status: CertificateStatus?
        /// Running step while the certificate is being fetched.
        public let step: String?
        /// Issuer.
        public let issuer: String?
        /// Start of validity.
        public let notBefore: Date?
        /// End of validity.
        public let notAfter: Date?
        /// Last error message.
        public let lastError: String?
        /// Time of the last issuing attempt.
        public let lastAttempt: Date?
        /// Parts that use the certificate.
        public let usedBy: [String]?
        /// Creation time.
        public let createdAt: Date?
        /// Last change.
        public let updatedAt: Date?
        /// DNS account (source `dns`).
        public let dnsAccount: Int?
        /// Own CA (source `ca`).
        public let caID: Int?
        /// Validity in days (sources `ca`, `self`).
        public let days: Int?
        /// Further ACME authority; `0` is Let's Encrypt.
        public let acmeCA: Int?
        /// Key type.
        public let keyType: CertificateKeyType?

        enum CodingKeys: String, CodingKey {
            case id, names, source
            case aliasZone = "alias_zone"
            case aliasPrefix = "alias_prefix"
            case staging
            case autoRenew = "auto_renew"
            case status, step, issuer
            case notBefore = "not_before"
            case notAfter = "not_after"
            case lastError = "last_error"
            case lastAttempt = "last_attempt"
            case usedBy = "used_by"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case dnsAccount = "dns_account"
            case caID = "ca_id"
            case days
            case acmeCA = "acme_ca"
            case keyType = "key_type"
        }
    }

    /// Body of ``Node64/Certificates/create(_:)``.
    ///
    /// Which fields apply depends on ``source``: `alias` needs `aliasZone` and `aliasPrefix`,
    /// `dns` needs `dnsAccount`, `ca` needs `caID` (and `days`), `self` uses `days` and `keyType`.
    public struct CertificateCreateInput: Encodable, Hashable, Sendable {
        /// DNS names or IP addresses.
        public var names: [String]
        /// How to issue the certificate.
        public var source: CertificateSource
        /// Alias zone (source `alias`).
        public var aliasZone: String?
        /// Alias prefix (source `alias`).
        public var aliasPrefix: String?
        /// Use the Let's Encrypt test environment.
        public var staging: Bool?
        /// Renew automatically (default on).
        public var autoRenew: Bool?
        /// DNS account (source `dns`).
        public var dnsAccount: Int?
        /// Own CA (source `ca`).
        public var caID: Int?
        /// Validity in days (sources `ca`, `self`); default 397, at most 825.
        public var days: Int?
        /// Further ACME authority instead of Let's Encrypt (`0`).
        public var acmeCA: Int?
        /// Key type (source `self`); default ECDSA.
        public var keyType: CertificateKeyType?

        /// Creates a certificate request; optional fields left `nil` are not sent.
        public init(
            names: [String],
            source: CertificateSource,
            aliasZone: String? = nil,
            aliasPrefix: String? = nil,
            staging: Bool? = nil,
            autoRenew: Bool? = nil,
            dnsAccount: Int? = nil,
            caID: Int? = nil,
            days: Int? = nil,
            acmeCA: Int? = nil,
            keyType: CertificateKeyType? = nil
        ) {
            self.names = names
            self.source = source
            self.aliasZone = aliasZone
            self.aliasPrefix = aliasPrefix
            self.staging = staging
            self.autoRenew = autoRenew
            self.dnsAccount = dnsAccount
            self.caID = caID
            self.days = days
            self.acmeCA = acmeCA
            self.keyType = keyType
        }

        enum CodingKeys: String, CodingKey {
            case names, source
            case aliasZone = "alias_zone"
            case aliasPrefix = "alias_prefix"
            case staging
            case autoRenew = "auto_renew"
            case dnsAccount = "dns_account"
            case caID = "ca_id"
            case days
            case acmeCA = "acme_ca"
            case keyType = "key_type"
        }
    }

    /// JSON body of ``Node64/Certificates/upload(_:)``: PEM `cert` and `key`, or a PKCS#12 file in `p12`.
    ///
    /// The key and password are secrets; do not log them. The password is not stored by the node.
    public struct CertificateUploadInput: Encodable, Hashable, Sendable {
        /// PEM certificate with chain.
        public var cert: String?
        /// PEM private key (may be encrypted).
        public var key: String?
        /// Password of an encrypted key or PKCS#12 file.
        public var password: String?
        /// PKCS#12 (`.pfx`/`.p12`) instead of `cert` and `key`; sent as Base64.
        public var p12: Data?

        /// Creates an upload input: either `cert` and `key` (PEM) or `p12`.
        public init(cert: String? = nil, key: String? = nil, password: String? = nil, p12: Data? = nil) {
            self.cert = cert
            self.key = key
            self.password = password
            self.p12 = p12
        }
    }

    /// Details of an issued certificate (`ETag` of the response is the fingerprint).
    ///
    /// Schema `CertMeta`.
    public struct CertMeta: Codable, Hashable, Sendable, Identifiable {
        /// Certificate ID.
        public let id: Int
        /// DNS names and IP addresses.
        public let names: [String]?
        /// Issuer.
        public let issuer: String?
        /// Serial number (hex).
        public let serial: String?
        /// Start of validity.
        public let notBefore: Date?
        /// End of validity.
        public let notAfter: Date?
        /// Days until expiry.
        public let daysLeft: Int?
        /// SHA-256 of the certificate (hex), equal to the ETag.
        public let fingerprintSHA256: String?

        enum CodingKeys: String, CodingKey {
            case id, names, issuer, serial
            case notBefore = "not_before"
            case notAfter = "not_after"
            case daysLeft = "days_left"
            case fingerprintSHA256 = "fingerprint_sha256"
        }
    }

    /// Result of ``Node64/Certificates/bundle(_:format:ifNoneMatch:)``.
    public enum CertificateBundleResult: Sendable, Hashable {
        /// The file, with the `ETag` of the response (the certificate fingerprint).
        case changed(Data, etag: String?)
        /// The certificate did not change since the given ETag (HTTP 304).
        case notModified
    }

    /// ACME account (email and terms of service).
    ///
    /// Schema `CertAccount`.
    public struct CertAccount: Codable, Hashable, Sendable {
        /// Contact email.
        public let email: String?
        /// Whether the terms of service are accepted.
        public let tosAccepted: Bool?
        /// When the terms were accepted.
        public let tosAt: Date?
        /// URL of the terms of service.
        public let tosURL: String?

        enum CodingKeys: String, CodingKey {
            case email
            case tosAccepted = "tos_accepted"
            case tosAt = "tos_at"
            case tosURL = "tos_url"
        }
    }

    /// Credentials of a DNS provider for DNS-01 validation, without secret values.
    ///
    /// Schema `DNSAccount`.
    public struct DNSAccount: Codable, Hashable, Sendable, Identifiable {
        /// DNS account ID.
        public let id: Int
        /// Name.
        public let name: String?
        /// Provider ID (see ``DNSProvider``).
        public let provider: String?
        /// Display name of the provider.
        public let providerName: String?
        /// Non-secret fields; secret fields appear only as `"set"`.
        public let values: [String: String]?
        /// Certificates that use this account.
        public let usedBy: [String]?
        /// Creation time.
        public let createdAt: Date?
        /// Last change.
        public let updatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, name, provider
            case providerName = "provider_name"
            case values
            case usedBy = "used_by"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    /// A supported DNS provider with the fields its account needs.
    public struct DNSProvider: Codable, Hashable, Sendable, Identifiable {
        /// Provider ID, used as `provider` of a DNS account.
        public let id: String
        /// Display name.
        public let name: String?
        /// Documentation URL or text.
        public let docs: String?
        /// Fields to fill in.
        public let fields: [Field]?

        /// One input field of a DNS provider.
        public struct Field: Codable, Hashable, Sendable {
            /// Key in the account's `values`.
            public let key: String?
            /// Label.
            public let label: String?
            /// Secret value (stored, never returned).
            public let secret: Bool?
            /// Field may stay empty.
            public let optional: Bool?
            /// Default value.
            public let `default`: String?
        }
    }

    /// An own certificate authority.
    ///
    /// Schema `CA`.
    public struct CertificateAuthority: Codable, Hashable, Sendable, Identifiable {
        /// CA ID.
        public let id: Int
        /// Name.
        public let name: String?
        /// Subject.
        public let subject: String?
        /// End of validity.
        public let notAfter: Date?
        /// Imported rather than generated.
        public let imported: Bool?
        /// Self-signed root; otherwise an intermediate CA.
        public let root: Bool?
        /// Permitted DNS names.
        public let permittedDNS: [String]?
        /// Permitted IP ranges.
        public let permittedIP: [String]?
        /// SHA-256 fingerprint.
        public let fingerprintSHA256: String?
        /// Number of certificates issued with it.
        public let certificates: Int?
        /// Creation time.
        public let createdAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, name, subject
            case notAfter = "not_after"
            case imported, root
            case permittedDNS = "permitted_dns"
            case permittedIP = "permitted_ip"
            case fingerprintSHA256 = "fingerprint_sha256"
            case certificates
            case createdAt = "created_at"
        }
    }

    /// File format of ``Node64/Certificates/Authorities/file(_:format:)``.
    public struct CertificateAuthorityFileFormat: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// PEM (default).
        public static let pem: Self = "pem"
        /// DER for Windows and Android.
        public static let crt: Self = "crt"
        /// Profile for iOS and macOS.
        public static let mobileconfig: Self = "mobileconfig"
    }

    /// Import of an existing CA (also an intermediate CA with chain). Key and password are secrets.
    public struct CertificateAuthorityImportInput: Encodable, Hashable, Sendable {
        /// Name; empty uses the CN.
        public var name: String?
        /// PEM certificate.
        public var cert: String?
        /// PEM private key.
        public var key: String?
        /// Password of an encrypted key or PKCS#12 file.
        public var password: String?
        /// PKCS#12 file instead of `cert` and `key`; sent as Base64.
        public var p12: Data?

        /// Creates a CA import input: either `cert` and `key` (PEM) or `p12`.
        public init(name: String? = nil, cert: String? = nil, key: String? = nil, password: String? = nil, p12: Data? = nil) {
            self.name = name
            self.cert = cert
            self.key = key
            self.password = password
            self.p12 = p12
        }
    }

    /// An additional ACME authority besides Let's Encrypt.
    ///
    /// Schema `ACMECA`.
    public struct ACMEAuthority: Codable, Hashable, Sendable, Identifiable {
        /// Authority ID.
        public let id: Int
        /// Name.
        public let name: String?
        /// ACME directory URL.
        public let directory: String?
        /// Requires External Account Binding.
        public let eab: Bool?
        /// EAB key ID.
        public let eabKID: String?
        /// Uses a custom root certificate.
        public let customRoot: Bool?
        /// Number of certificates issued by it.
        public let certificates: Int?
        /// Creation time.
        public let createdAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, name, directory, eab
            case eabKID = "eab_kid"
            case customRoot = "custom_root"
            case certificates
            case createdAt = "created_at"
        }
    }
}
