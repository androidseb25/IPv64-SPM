import Foundation

extension Node64 {
    /// Mode of the DHCP server on this node.
    public struct DNS64DHCPMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Switched off.
        public static let off: Self = "off"
        /// Dry run: observes without handing out addresses.
        public static let observe: Self = "observe"
        /// Hands out addresses.
        public static let on: Self = "on"
    }

    /// Role of this node in the cluster.
    public struct DNS64DHCPRole: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Hands out addresses.
        public static let primary: Self = "primary"
        /// Answers only if no primary is reachable.
        public static let reserve: Self = "reserve"
    }

    /// Kind of error of an IPv6 Router Advertisement sender.
    public struct DNS64DHCPIPv6ErrorKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Interface not found.
        public static let noInterface: Self = "no_iface"
        /// Interface has no suitable address.
        public static let noAddress: Self = "no_addr"
        /// Sending failed.
        public static let send: Self = "send"
    }

    /// A DHCP network (one per interface). Schema `DNS64DHCPScope`.
    public struct DNS64DHCPScope: Codable, Hashable, Sendable, Identifiable {
        /// Network ID.
        public let id: Int
        /// Name.
        public let name: String?
        /// Host interface, also VLAN (`eth0.20`).
        public let interface: String?
        /// Subnet in CIDR notation, e.g. `192.168.1.0/24`.
        public let subnet: String?
        /// First address of the pool.
        public let rangeStart: String?
        /// Last address of the pool.
        public let rangeEnd: String?
        /// Default router; empty means none.
        public let router: String?
        /// DNS servers; empty means this node (recommended), at most 4.
        public let dns: [String]?
        /// Domain.
        public let domain: String?
        /// Lease time in hours (1-8760, 0 = 24).
        public let leaseHours: Int?
        /// NTP servers.
        public let ntp: [String]?
        /// Answers requests for addresses that do not fit here with NAK (switching over from the router).
        public let authoritative: Bool?
        /// PXE: TFTP server (option 66).
        public let bootServer: String?
        /// PXE: boot file for BIOS clients.
        public let bootBIOS: String?
        /// PXE: boot file for UEFI clients.
        public let bootUEFI: String?
        /// Boot file if the client already runs iPXE.
        public let bootIPXE: String?
        /// Network behind a DHCP relay (requests only with `giaddr`, several networks per interface possible).
        public let relay: Bool?
        /// Whether the network is on (read-only).
        public let enabled: Bool?
        /// Creation time (read-only).
        public let createdAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, name, interface, subnet
            case rangeStart = "range_start"
            case rangeEnd = "range_end"
            case router, dns, domain
            case leaseHours = "lease_hours"
            case ntp, authoritative
            case bootServer = "boot_server"
            case bootBIOS = "boot_bios"
            case bootUEFI = "boot_uefi"
            case bootIPXE = "boot_ipxe"
            case relay, enabled
            case createdAt = "created_at"
        }
    }

    /// Writable fields of a DHCP network for create and update.
    public struct DNS64DHCPScopeInput: Encodable, Hashable, Sendable {
        /// Name.
        public var name: String?
        /// Host interface, also VLAN (`eth0.20`).
        public var interface: String
        /// Subnet in CIDR notation, e.g. `192.168.1.0/24`.
        public var subnet: String
        /// First address of the pool.
        public var rangeStart: String
        /// Last address of the pool.
        public var rangeEnd: String
        /// Default router; empty means none.
        public var router: String?
        /// DNS servers; empty means this node (recommended), at most 4.
        public var dns: [String]?
        /// Domain.
        public var domain: String?
        /// Lease time in hours (1-8760, 0 = 24).
        public var leaseHours: Int?
        /// NTP servers.
        public var ntp: [String]?
        /// Answers requests for addresses that do not fit here with NAK.
        public var authoritative: Bool?
        /// PXE: TFTP server (option 66).
        public var bootServer: String?
        /// PXE: boot file for BIOS clients.
        public var bootBIOS: String?
        /// PXE: boot file for UEFI clients.
        public var bootUEFI: String?
        /// Boot file if the client already runs iPXE.
        public var bootIPXE: String?
        /// Network behind a DHCP relay.
        public var relay: Bool?

        /// Creates a network input; optional fields left `nil` are not sent.
        public init(
            interface: String,
            subnet: String,
            rangeStart: String,
            rangeEnd: String,
            name: String? = nil,
            router: String? = nil,
            dns: [String]? = nil,
            domain: String? = nil,
            leaseHours: Int? = nil,
            ntp: [String]? = nil,
            authoritative: Bool? = nil,
            bootServer: String? = nil,
            bootBIOS: String? = nil,
            bootUEFI: String? = nil,
            bootIPXE: String? = nil,
            relay: Bool? = nil
        ) {
            self.interface = interface
            self.subnet = subnet
            self.rangeStart = rangeStart
            self.rangeEnd = rangeEnd
            self.name = name
            self.router = router
            self.dns = dns
            self.domain = domain
            self.leaseHours = leaseHours
            self.ntp = ntp
            self.authoritative = authoritative
            self.bootServer = bootServer
            self.bootBIOS = bootBIOS
            self.bootUEFI = bootUEFI
            self.bootIPXE = bootIPXE
            self.relay = relay
        }

        enum CodingKeys: String, CodingKey {
            case name, interface, subnet
            case rangeStart = "range_start"
            case rangeEnd = "range_end"
            case router, dns, domain
            case leaseHours = "lease_hours"
            case ntp, authoritative
            case bootServer = "boot_server"
            case bootBIOS = "boot_bios"
            case bootUEFI = "boot_uefi"
            case bootIPXE = "boot_ipxe"
            case relay
        }
    }

    /// A fixed DHCP address (MAC and IP are unique per network). Schema `DNS64DHCPReservation`.
    public struct DNS64DHCPReservation: Codable, Hashable, Sendable, Identifiable {
        /// Reservation ID.
        public let id: Int
        /// ID of the DHCP network.
        public let scopeID: Int?
        /// MAC address, e.g. `aa:bb:cc:dd:ee:ff`.
        public let mac: String?
        /// Fixed IP address.
        public let ip: String?
        /// Host name.
        public let name: String?
        /// Comment.
        public let comment: String?
        /// Only when creating: also adds the MAC to this device group.
        public let groupID: Int?

        enum CodingKeys: String, CodingKey {
            case id
            case scopeID = "scope_id"
            case mac, ip, name, comment
            case groupID = "group_id"
        }
    }

    /// Writable fields of a fixed DHCP address for create and update.
    public struct DNS64DHCPReservationInput: Encodable, Hashable, Sendable {
        /// ID of the DHCP network.
        public var scopeID: Int
        /// MAC address, e.g. `aa:bb:cc:dd:ee:ff`.
        public var mac: String
        /// Fixed IP address.
        public var ip: String
        /// Host name.
        public var name: String?
        /// Comment.
        public var comment: String?
        /// Only when creating: also adds the MAC to this device group.
        public var groupID: Int?

        /// Creates a reservation input; optional fields left `nil` are not sent.
        public init(scopeID: Int, mac: String, ip: String, name: String? = nil, comment: String? = nil, groupID: Int? = nil) {
            self.scopeID = scopeID
            self.mac = mac
            self.ip = ip
            self.name = name
            self.comment = comment
            self.groupID = groupID
        }

        enum CodingKeys: String, CodingKey {
            case scopeID = "scope_id"
            case mac, ip, name, comment
            case groupID = "group_id"
        }
    }

    /// Settings of the IPv6 DNS announcement (Router Advertisement).
    public struct DNS64DHCPIPv6Config: Codable, Hashable, Sendable {
        /// Whether the announcement is on.
        public let enabled: Bool?
        /// Interfaces to announce on (at most 8).
        public let interfaces: [String]?
        /// Search domain (DNSSL); empty means none.
        public let domain: String?
    }

    /// Writable fields of ``DNS64DHCPIPv6Config``.
    public struct DNS64DHCPIPv6Input: Encodable, Hashable, Sendable {
        /// Whether the announcement is on.
        public var enabled: Bool?
        /// Interfaces to announce on (at most 8).
        public var interfaces: [String]?
        /// Search domain (DNSSL); empty means none.
        public var domain: String?

        /// Creates an input; fields left `nil` are not sent.
        public init(enabled: Bool? = nil, interfaces: [String]? = nil, domain: String? = nil) {
            self.enabled = enabled
            self.interfaces = interfaces
            self.domain = domain
        }
    }

    /// Sender state of one interface of the IPv6 DNS announcement.
    public struct DNS64DHCPIPv6InterfaceStatus: Codable, Hashable, Sendable {
        /// Interface name.
        public let interface: String?
        /// Announced DNS server addresses.
        public let dns: [String]?
        /// Time of the last advertisement.
        public let lastSent: Date?
        /// Error text.
        public let error: String?
        /// Kind of error.
        public let errorKind: DNS64DHCPIPv6ErrorKind?

        enum CodingKeys: String, CodingKey {
            case interface, dns
            case lastSent = "last_sent"
            case error
            case errorKind = "error_kind"
        }
    }

    /// A prefix announced by another router.
    public struct DNS64DHCPIPv6Prefix: Codable, Hashable, Sendable {
        /// Prefix.
        public let prefix: String?
        /// Whether hosts may build addresses by SLAAC.
        public let slaac: Bool?
        /// Whether the prefix is on-link.
        public let onLink: Bool?
        /// Valid lifetime in seconds.
        public let validLifetime: Int?

        enum CodingKeys: String, CodingKey {
            case prefix, slaac
            case onLink = "on_link"
            case validLifetime = "valid_lifetime"
        }
    }

    /// A router seen on the network (Router Advertisement).
    public struct DNS64DHCPIPv6Router: Codable, Hashable, Sendable {
        /// Interface it was seen on.
        public let interface: String?
        /// Source address, e.g. `fe80::1`.
        public let source: String?
        /// Router lifetime in seconds, 0 = no default router.
        public let routerLifetime: Int?
        /// M flag: addresses via DHCPv6.
        public let managed: Bool?
        /// O flag: further settings via DHCPv6.
        public let other: Bool?
        /// Announced prefixes.
        public let prefixes: [DNS64DHCPIPv6Prefix]?
        /// Announced DNS servers.
        public let dns: [String]?
        /// Announced search domains.
        public let domains: [String]?
        /// Time it was last seen.
        public let lastSeen: Date?

        enum CodingKeys: String, CodingKey {
            case interface, source
            case routerLifetime = "router_lifetime"
            case managed, other, prefixes, dns, domains
            case lastSeen = "last_seen"
        }
    }

    /// Settings and state of the IPv6 DNS announcement.
    public struct DNS64DHCPIPv6State: Codable, Hashable, Sendable {
        /// Settings.
        public let config: DNS64DHCPIPv6Config?
        /// Whether the sender runs.
        public let running: Bool?
        /// Socket error (for example without `cap_net_raw`).
        public let error: String?
        /// State per interface.
        public let status: [DNS64DHCPIPv6InterfaceStatus]?
        /// Routers of other devices (only while the sender runs).
        public let routers: [DNS64DHCPIPv6Router]?
    }

    /// Result of ``Node64/DNS64/DHCP-swift.struct/probeIPv6()``.
    public struct DNS64DHCPIPv6Probe: Codable, Hashable, Sendable {
        /// Routers that answered.
        public let routers: [DNS64DHCPIPv6Router]?
        /// Error text.
        public let error: String?
    }
}
