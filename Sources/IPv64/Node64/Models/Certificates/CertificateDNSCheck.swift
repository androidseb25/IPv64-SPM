import Foundation

extension Node64 {
    /// Own resolvers of the DNS-01 check. Schema of `GET /certs/dns-check`.
    public struct CertDNSCheck: Codable, Hashable, Sendable {
        /// Own resolvers: IP addresses (port 53) or `https://`, `tls://`, `quic://` URLs. Empty = built-in ones only.
        public let resolvers: [String]?
    }

    /// One way the DNS-01 check can take.
    public struct CertDNSCheckPath: Codable, Hashable, Sendable {
        /// Name of the way.
        public let name: String?
        /// Directly via the ipv64 name servers (otherwise a public resolver).
        public let direct: Bool?
        /// The way works.
        public let ok: Bool?
        /// Details.
        public let detail: String?
    }

    /// Result of the DNS-01 check. Schema of `POST /certs/dns-check/run`.
    public struct CertDNSCheckResult: Codable, Hashable, Sendable {
        /// All tested ways.
        public let paths: [CertDNSCheckPath]?
        /// A direct way works.
        public let directOK: Bool?
        /// A public resolver works.
        public let publicOK: Bool?
        /// At least one way works (one is enough).
        public let ok: Bool?

        enum CodingKeys: String, CodingKey {
            case paths
            case directOK = "direct_ok"
            case publicOK = "public_ok"
            case ok
        }
    }
}
