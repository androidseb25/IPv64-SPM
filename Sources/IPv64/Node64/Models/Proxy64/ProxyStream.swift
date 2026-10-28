import Foundation

extension Node64 {
    /// Connection counters of a stream.
    public struct ProxyStreamStats: Codable, Hashable, Sendable {
        /// Total connections since the start.
        public let connections: Int?
        /// Currently active connections.
        public let active: Int?
        /// Bytes received from clients.
        public let bytesIn: Int?
        /// Bytes sent to clients.
        public let bytesOut: Int?

        enum CodingKeys: String, CodingKey {
            case connections, active
            case bytesIn = "bytes_in"
            case bytesOut = "bytes_out"
        }
    }

    /// A TCP/UDP stream. Schema `Stream` (renamed, the name is too generic).
    public struct ProxyStream: Codable, Hashable, Sendable, Identifiable {
        /// Stream ID.
        public let id: Int
        /// Name of the stream.
        public let name: String?
        /// Whether the stream is enabled.
        public let enabled: Bool?
        /// Port the stream listens on.
        public let listenPort: Int?
        /// Whether TCP is served.
        public let tcp: Bool?
        /// Whether UDP is served.
        public let udp: Bool?
        /// Target name or IP.
        public let targetHost: String?
        /// Target port.
        public let targetPort: Int?
        /// TCP: terminate TLS with this certificate; `0` = raw.
        public let tlsCertID: Int?
        /// Creation time.
        public let createdAt: Date?
        /// Time of the last update.
        public let updatedAt: Date?
        /// Whether the stream is running.
        public let running: Bool?
        /// Reachability of the target (free-form object).
        public let reach: JSONValue?
        /// Why a port (`tcp`/`udp`) is not open.
        public let listenErrors: [String: String]?
        /// Connection counters.
        public let stats: ProxyStreamStats?
        /// Name of the certificate used for TLS termination.
        public let certName: String?
        /// Country filter mode; changing it does not restart the stream.
        public let geoMode: CDNGeoMode?
        /// ISO country codes, at most 60.
        public let geoCountries: [String]?

        enum CodingKeys: String, CodingKey {
            case id, name, enabled
            case listenPort = "listen_port"
            case tcp, udp
            case targetHost = "target_host"
            case targetPort = "target_port"
            case tlsCertID = "tls_cert_id"
            case createdAt = "created_at"
            case updatedAt = "updated_at"
            case running, reach
            case listenErrors = "listen_errors"
            case stats
            case certName = "cert_name"
            case geoMode = "geo_mode"
            case geoCountries = "geo_countries"
        }
    }

    /// Writable fields of a stream. Schema `StreamInput` (renamed).
    public struct ProxyStreamInput: Encodable, Hashable, Sendable {
        /// Name of the stream.
        public var name: String?
        /// Whether it is enabled.
        public var enabled: Bool?
        /// Port the stream listens on.
        public var listenPort: Int?
        /// Whether TCP is served.
        public var tcp: Bool?
        /// Whether UDP is served.
        public var udp: Bool?
        /// Target name or IP.
        public var targetHost: String?
        /// Target port.
        public var targetPort: Int?
        /// TCP: terminate TLS with this certificate; `0` = raw.
        public var tlsCertID: Int?
        /// Country filter mode.
        public var geoMode: CDNGeoMode?
        /// ISO country codes, at most 60.
        public var geoCountries: [String]?

        /// Creates a stream input; pass only the fields you want to set.
        public init(
            name: String? = nil,
            enabled: Bool? = nil,
            listenPort: Int? = nil,
            tcp: Bool? = nil,
            udp: Bool? = nil,
            targetHost: String? = nil,
            targetPort: Int? = nil,
            tlsCertID: Int? = nil,
            geoMode: CDNGeoMode? = nil,
            geoCountries: [String]? = nil
        ) {
            self.name = name
            self.enabled = enabled
            self.listenPort = listenPort
            self.tcp = tcp
            self.udp = udp
            self.targetHost = targetHost
            self.targetPort = targetPort
            self.tlsCertID = tlsCertID
            self.geoMode = geoMode
            self.geoCountries = geoCountries
        }

        enum CodingKeys: String, CodingKey {
            case name, enabled
            case listenPort = "listen_port"
            case tcp, udp
            case targetHost = "target_host"
            case targetPort = "target_port"
            case tlsCertID = "tls_cert_id"
            case geoMode = "geo_mode"
            case geoCountries = "geo_countries"
        }
    }
}
