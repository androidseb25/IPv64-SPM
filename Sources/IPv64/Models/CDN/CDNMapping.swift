import Foundation

/// A port mapping of a CDN domain: forwards a public port of the CDN server to a port on your server.
public struct CDNMapping: Codable, Hashable, Sendable, Identifiable {
    /// Mapping ID.
    public let id: String
    /// Name, e.g. `Minecraft`.
    public let name: String?
    /// Public port on the CDN server.
    public let listenPort: Int?
    /// Transport protocol.
    public let transport: CDNTransport?
    /// Port on your server.
    public let targetPort: Int?
    /// Record token of the target.
    public let record: String?
    /// Name of the target, e.g. `mc.beispiel.ipv64.de`.
    public let fqdn: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case listenPort = "listen_port"
        case transport
        case targetPort = "target_port"
        case record, fqdn
    }
}

/// Transport protocol of a ``CDNMapping``.
public struct CDNTransport: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let tcp: Self = "tcp"
    public static let udp: Self = "udp"
}
