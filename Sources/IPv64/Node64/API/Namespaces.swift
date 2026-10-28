import Foundation

// Top-level areas of the Node64 API. Each area's methods and sub-areas live in
// their own file under `Node64/API/` as extensions of these structs.

extension Node64 {
    /// Node itself: status, modules, settings, API keys, backups, logs.
    public var node: Node { Node(client: self) }
    /// Healthchecks: checks, events, maintenance, push, channels, status pages, Docker, Proxmox.
    public var hc: HC { HC(client: self) }
    /// DynDNS updater of the node.
    public var dyndns: DynDNS { DynDNS(client: self) }
    /// DNS64 resolver: statistics, lists, records, groups, forwards, rewrites, zones.
    public var dns64: DNS64 { DNS64(client: self) }
    /// PROXY64 reverse proxy (paths `/cdn64/…`): hosts, streams, access lists, protection.
    public var proxy64: Proxy64 { Proxy64(client: self) }
    /// Port claims and the edge (public entry point).
    public var ports: Ports { Ports(client: self) }
    /// TLS certificates, certificate authorities and ACME settings.
    public var certificates: Certificates { Certificates(client: self) }
    /// Link of the node to an ipv64.net account.
    public var link: Link { Link(client: self) }
    /// Local cluster of nodes.
    public var cluster: Cluster { Cluster(client: self) }
    /// Honeypot64 sensor.
    public var honeypot: Honeypot { Honeypot(client: self) }

    /// Endpoints of the *Node* area.
    public struct Node: Sendable { let client: Node64 }
    /// Endpoints of the *Healthchecks* and *Benachrichtigungen* areas.
    public struct HC: Sendable { let client: Node64 }
    /// Endpoints of the *DynDNS* area.
    public struct DynDNS: Sendable { let client: Node64 }
    /// Endpoints of the *DNS64* area.
    public struct DNS64: Sendable { let client: Node64 }
    /// Endpoints of the *PROXY64* area.
    public struct Proxy64: Sendable { let client: Node64 }
    /// Port endpoints of the *Ports & Zertifikate* area.
    public struct Ports: Sendable { let client: Node64 }
    /// Certificate endpoints of the *Ports & Zertifikate* area.
    public struct Certificates: Sendable { let client: Node64 }
    /// Endpoints of the *Verknüpfung* area.
    public struct Link: Sendable { let client: Node64 }
    /// Endpoints of the *Cluster* area.
    public struct Cluster: Sendable { let client: Node64 }
    /// Endpoints of the *Honeypot64* area.
    public struct Honeypot: Sendable { let client: Node64 }
}
