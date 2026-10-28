import Foundation

/// Provisioning state of a Cloud Router resource (gateway, peer, route, firewall rule, public IP, port forward).
///
/// Changes are applied asynchronously by a background service. A resource is
/// done once its state is ``ready``.
public struct CloudRouterState: IPv64OpenEnum {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }

    /// The resource is set up and active.
    public static let ready: Self = "ready"
    /// The resource is being created.
    public static let creating: Self = "creating"
    /// A change is being applied.
    public static let applying: Self = "applying"
    /// The resource is being deleted.
    public static let deleting: Self = "deleting"
}

/// Result of deleting a route, firewall rule, public IP or port forward (`202 Accepted`).
public struct CloudRouterDeletion: Codable, Hashable, Sendable, Identifiable {
    /// ID of the resource being deleted.
    public let id: Int?
    /// State of the resource, `deleting`.
    public let state: CloudRouterState?
}
