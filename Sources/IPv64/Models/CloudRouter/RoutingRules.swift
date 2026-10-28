import Foundation

/// A static route of a Cloud Router.
public struct Route: Codable, Hashable, Sendable, Identifiable {
    /// ID.
    public let id: Int
    /// Destination network (CIDR).
    public let destination: String?
    /// Next hop.
    public let gateway: String?
    /// Administrative distance.
    public let distance: Int?
    /// ID of the peer behind which the network lives.
    public let peer: String?
    /// Created by the system; cannot be deleted.
    public let system: Bool?
    /// Disabled.
    public let disabled: Bool?
    /// Provisioning state.
    public let state: CloudRouterState?
}

/// A firewall rule of a Cloud Router.
public struct FirewallRule: Codable, Hashable, Sendable, Identifiable {
    /// ID.
    public let id: Int
    /// Chain.
    public let chain: FirewallRuleChain?
    /// Action.
    public let action: FirewallRuleAction?
    /// Address family.
    public let family: FirewallRuleFamily?
    /// Source IP or CIDR.
    public let source: String?
    /// Destination IP or CIDR.
    public let destination: String?
    /// Disabled.
    public let disabled: Bool?
    /// Provisioning state.
    public let state: CloudRouterState?
}

/// Firewall chain.
public struct FirewallRuleChain: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let forward: Self = "forward"
    public static let input: Self = "input"
    public static let output: Self = "output"
}

/// Firewall action.
public struct FirewallRuleAction: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let accept: Self = "accept"
    public static let drop: Self = "drop"
}

/// Address family of a ``FirewallRule``.
public struct FirewallRuleFamily: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let ipv4: Self = "ipv4"
    public static let ipv6: Self = "ipv6"
}

/// A port forward of a gateway.
public struct PortForward: Codable, Hashable, Sendable, Identifiable {
    /// ID.
    public let id: Int
    /// Name.
    public let name: String?
    /// Destination IP inside the tunnel.
    public let destination: String?
    /// Destination port.
    public let targetPort: Int?
    /// Protocol.
    public let `protocol`: PortForwardProtocol?
    /// Public port assigned by the server.
    public let publicPort: Int?
    /// Which public address is used.
    public let publicIP: PortForwardPublicIP?
    /// Disabled.
    public let disabled: Bool?
    /// Provisioning state.
    public let state: CloudRouterState?

    enum CodingKeys: String, CodingKey {
        case id, name, destination
        case targetPort = "target_port"
        case `protocol`
        case publicPort = "public_port"
        case publicIP = "public_ip"
        case disabled, state
    }
}

/// Transport protocol of a ``PortForward``.
public struct PortForwardProtocol: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let tcp: Self = "tcp"
    public static let udp: Self = "udp"
}

/// Public address a ``PortForward`` listens on.
public struct PortForwardPublicIP: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// The address of the VPN server.
    public static let server: Self = "server"
    /// The public IP of the router (create it first).
    public static let router: Self = "router"
}
