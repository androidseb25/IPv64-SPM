import Foundation

extension Node64 {
    /// A network under early-warning watch at ipv64.
    public struct Honeypot64WatchNetwork: Codable, Hashable, Sendable, Identifiable {
        /// ID at ipv64.
        public let id: Int
        /// Network in CIDR notation.
        public let cidr: String?
        /// Label (up to 64 characters).
        public let label: String?
        /// Verified by ipv64.
        public let verified: Bool?
        /// Creation time (as sent by the node).
        public let createdAt: String?

        enum CodingKeys: String, CodingKey {
            case id, cidr, label, verified
            case createdAt = "created_at"
        }
    }

    /// Overview of the early warning. Schema of `GET /honeypot/watch`.
    public struct Honeypot64Watch: Codable, Hashable, Sendable {
        /// Limits of the account.
        public let limits: Limits?
        /// Watched networks.
        public let networks: [Honeypot64WatchNetwork]?
        /// DynDNS addresses that are watched as well.
        public let dyndns: [DynDNSAddress]?
        /// The limit of networks is reached.
        public let full: Bool?
        /// A retrieval is running.
        public let running: Bool?
        /// State of the retrieval and latest hits (free-form object in the spec).
        public let state: JSONValue?

        /// Limits of the early warning.
        public struct Limits: Codable, Hashable, Sendable {
            /// Maximum number of networks.
            public let max: Int?
            /// Smallest allowed IPv4 prefix length.
            public let minPrefixV4: Int?
            /// Smallest allowed IPv6 prefix length.
            public let minPrefixV6: Int?

            enum CodingKeys: String, CodingKey {
                case max
                case minPrefixV4 = "min_prefix_v4"
                case minPrefixV6 = "min_prefix_v6"
            }
        }

        /// A DynDNS address.
        public struct DynDNSAddress: Codable, Hashable, Sendable {
            /// IP address.
            public let ip: String?
            /// Domain.
            public let domain: String?
        }
    }

    /// Result of ``Node64/Honeypot/Watch/check()``.
    public struct Honeypot64WatchCheckResult: Codable, Hashable, Sendable {
        /// Number of new hits.
        public let newHits: Int?
        /// State of the retrieval (free-form object in the spec).
        public let state: JSONValue?

        enum CodingKeys: String, CodingKey {
            case newHits = "new_hits"
            case state
        }
    }

    /// Request body of ``Node64/Honeypot/certificate(_:)``.
    public struct Honeypot64CertificateInput: Encodable, Hashable, Sendable {
        /// ipv64 domain of the account.
        public var domain: String
        /// Decoy names (prefix or full name under the domain; no wildcard, not the domain itself, at most 20).
        public var names: [String]
        /// IPv4/IPv6 addresses or one name (CNAME) for which DNS records are created at ipv64; existing ones stay.
        public var dnsTargets: [String]?

        public init(domain: String, names: [String], dnsTargets: [String]? = nil) {
            self.domain = domain
            self.names = names
            self.dnsTargets = dnsTargets
        }

        enum CodingKeys: String, CodingKey {
            case domain, names
            case dnsTargets = "dns_targets"
        }
    }

    /// Result of ``Node64/Honeypot/certificate(_:)`` (202, issuing continues in the background).
    public struct Honeypot64CertificateResult: Codable, Hashable, Sendable {
        /// ID of the certificate; selected in the settings (`cert_id`).
        public let certID: Int?
        /// Names of the certificate.
        public let names: [String]?
        /// The certificate was selected in the settings.
        public let selected: Bool?
        /// DNS records per name.
        public let dns: [DNSEntry]?
        /// Error while creating the DNS records.
        public let dnsError: String?

        /// DNS record outcome.
        public struct DNSEntry: Codable, Hashable, Sendable {
            /// Record name.
            public let name: String?
            /// Record type.
            public let type: String?
            /// `created`, `exists` or `error`.
            public let result: String?
            /// Error text.
            public let error: String?
        }

        enum CodingKeys: String, CodingKey {
            case certID = "cert_id"
            case names, selected, dns
            case dnsError = "dns_error"
        }
    }
}
