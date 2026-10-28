import Foundation

/// An entry of the access list of a CDN domain.
///
/// Whether the list allows or blocks is set by ``CDNDomain/Proxy/AccessList/mode``.
public struct AccessListEntry: Codable, Hashable, Sendable, Identifiable {
    /// Entry ID.
    public let id: Int
    /// IP address or network in CIDR notation, e.g. `198.51.100.0/24`.
    public let address: String?
}
