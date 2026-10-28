import Foundation

/// A Cloud Router with its gateways and public IPs.
public struct CloudRouter: Codable, Hashable, Sendable, Identifiable {
    /// Router ID (32 characters, also usable as token).
    public let id: String
    /// Name.
    public let name: String?
    /// Internal VRF name, e.g. `vrf522a`.
    public let vrf: String?
    /// Blocked because the traffic limit was reached.
    public let trafficLimited: Bool?
    /// Gateways of the router (including their peers).
    public let gateways: [Gateway]?
    /// Public IPs of the router.
    public let publicIPs: [PublicIP]?

    enum CodingKeys: String, CodingKey {
        case id, name, vrf
        case trafficLimited = "traffic_limited"
        case gateways
        case publicIPs = "public_ips"
    }
}

/// A public IPv6 address of a ``CloudRouter``.
public struct PublicIP: Codable, Hashable, Sendable, Identifiable {
    /// ID.
    public let id: Int
    /// Address.
    public let ip: String?
    /// Address family.
    public let type: PublicIPFamily?
    /// Disabled.
    public let disabled: Bool?
    /// Provisioning state.
    public let state: CloudRouterState?
    /// Creation time.
    public let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, ip, type, disabled, state
        case createdAt = "created_at"
    }
}

/// Address family of a ``PublicIP``.
public struct PublicIPFamily: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let ipv4: Self = "ipv4"
    public static let ipv6: Self = "ipv6"
}
