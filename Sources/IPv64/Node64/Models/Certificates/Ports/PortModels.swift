import Foundation

extension Node64 {
    /// Transport protocol of a port (`tcp` or `udp`).
    public struct PortProtocol: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let tcp: Self = "tcp"
        public static let udp: Self = "udp"
    }

    /// Port used by a part of the node.
    ///
    /// Schema `PortClaim`.
    public struct PortClaim: Codable, Hashable, Sendable {
        /// Part that uses the port, e.g. `web`, `edge`, `dns64`, `cdn64`.
        public let owner: String?
        /// Purpose of the port.
        public let purpose: String?
        /// Transport protocol.
        public let proto: PortProtocol?
        /// Port number.
        public let port: Int?
        /// Bind address; missing means all addresses.
        public let bind: String?
        /// Whether the port is open or switched on.
        public let active: Bool?
        /// Other parts that use the same port, e.g. `dns64 (DoH)`.
        public let conflicts: [String]?
    }

    /// Result of ``Node64/Ports/list()``.
    public struct PortOverview: Codable, Hashable, Sendable {
        /// All port claims, including overlaps (see ``PortClaim/conflicts``).
        public let ports: [PortClaim]?
        /// State of the shared entry point (edge).
        public let edge: EdgeStatus?
    }

    /// Result of ``Node64/Ports/probe(port:transport:bind:)``.
    public struct PortProbeResult: Codable, Hashable, Sendable {
        /// Whether the port is free on the host.
        public let free: Bool?
        /// Part or process that uses the port.
        public let usedBy: String?
        /// Purpose of the port.
        public let purpose: String?
        /// Error message of the probe.
        public let error: String?

        enum CodingKeys: String, CodingKey {
            case free
            case usedBy = "used_by"
            case purpose, error
        }
    }

    /// Response to requests for unknown names at the edge.
    public struct EdgeDefaultResponse: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Answer `404`.
        public static let notFound: Self = "404"
        /// Close the connection.
        public static let close: Self = "close"
        /// Redirect to ``EdgeConfig/defaultURL``.
        public static let redirect: Self = "redirect"
        /// Show ``EdgeConfig/defaultHTML``.
        public static let html: Self = "html"
    }

    /// Settings of the shared entry point (edge). Also the body of ``Node64/Ports/Edge/update(_:)``.
    ///
    /// Schema `EdgeConfig`. Every field is optional; missing fields stay unchanged on update.
    public struct EdgeConfig: Codable, Hashable, Sendable {
        /// Bind address; `""` means all addresses.
        public var bind: String?
        /// HTTP port; `0` is off, default 80.
        public var httpPort: Int?
        /// HTTPS port; `0` is off, default 443.
        public var httpsPort: Int?
        /// HTTPS port from the visitors' view (redirect, Alt-Svc); `0` uses `httpsPort`.
        public var publicPort: Int?
        /// HTTP/3 (QUIC) on `httpsPort`/UDP.
        public var http3: Bool?
        /// Response for unknown names.
        public var defaultResponse: EdgeDefaultResponse?
        /// Target URL for ``EdgeDefaultResponse/redirect``.
        public var defaultURL: String?
        /// HTML for ``EdgeDefaultResponse/html``.
        public var defaultHTML: String?

        /// Creates an edge configuration change; fields left `nil` are not sent and stay unchanged.
        public init(
            bind: String? = nil,
            httpPort: Int? = nil,
            httpsPort: Int? = nil,
            publicPort: Int? = nil,
            http3: Bool? = nil,
            defaultResponse: EdgeDefaultResponse? = nil,
            defaultURL: String? = nil,
            defaultHTML: String? = nil
        ) {
            self.bind = bind
            self.httpPort = httpPort
            self.httpsPort = httpsPort
            self.publicPort = publicPort
            self.http3 = http3
            self.defaultResponse = defaultResponse
            self.defaultURL = defaultURL
            self.defaultHTML = defaultHTML
        }

        enum CodingKeys: String, CodingKey {
            case bind
            case httpPort = "http_port"
            case httpsPort = "https_port"
            case publicPort = "public_port"
            case http3
            case defaultResponse = "default"
            case defaultURL = "default_url"
            case defaultHTML = "default_html"
        }
    }

    /// Kind of an edge listener.
    public struct EdgeListenerName: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let http: Self = "http"
        public static let https: Self = "https"
        public static let http3: Self = "http3"
    }

    /// State of the shared entry point (edge): settings, listeners and registered names.
    ///
    /// Schema `EdgeStatus`.
    public struct EdgeStatus: Codable, Hashable, Sendable {
        /// Current settings.
        public let config: EdgeConfig?
        /// Listeners; ports open only while a module needs them.
        public let listeners: [Listener]?
        /// Names registered at the edge.
        public let names: [RegisteredName]?

        /// One listener of the edge.
        public struct Listener: Codable, Hashable, Sendable {
            /// Kind of listener.
            public let name: EdgeListenerName?
            /// Transport protocol.
            public let proto: String?
            /// Port number.
            public let port: Int?
            /// Whether a module currently needs the port.
            public let needed: Bool?
            /// Whether the listener is running.
            public let running: Bool?
            /// Bound address.
            public let addr: String?
            /// Error when starting the listener.
            public let error: String?
        }

        /// A name registered at the edge.
        public struct RegisteredName: Codable, Hashable, Sendable {
            /// Registered host name.
            public let name: String?
            /// Path below the name.
            public let path: String?
            /// Part that registered the name.
            public let owner: String?
        }
    }

    /// Settings of the Node64 interface behind the edge (`GET /edge/ui`).
    ///
    /// The response of `PUT /edge/ui` documents only `name` and `isPublic`; the other fields are then `nil`.
    public struct EdgeUI: Codable, Hashable, Sendable {
        /// Name of the interface at the edge; `""` is off.
        public let name: String?
        /// Also reachable from the internet (default: own network only).
        public let isPublic: Bool?
        /// Certificate: `auto`, `self` or an ID from `/certs`.
        public let cert: String?
        /// `NODE64_TLS_CERT` is set: the HTTPS port uses that file.
        public let certFromEnv: Bool?

        enum CodingKeys: String, CodingKey {
            case name
            case isPublic = "public"
            case cert
            case certFromEnv = "cert_from_env"
        }
    }
}
