import Foundation

extension Node64 {
    /// Remote management mode of the node in the ipv64 portal.
    public struct LinkRemoteManagement: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Full access.
        public static let full: LinkRemoteManagement = "full"
        /// Read-only access.
        public static let read: LinkRemoteManagement = "read"
        /// No remote management.
        public static let off: LinkRemoteManagement = "off"
    }

    /// State of the healthchecks sync with ipv64.
    ///
    /// Schema `Link`.
    public struct LinkStatus: Codable, Hashable, Sendable {
        /// The node is linked to an ipv64 account.
        public let linked: Bool?
        /// The node is currently connected to the hub.
        public let connected: Bool?
        /// ipv64 account ID.
        public let accountID: String?
        /// Plan of the account.
        public let plan: String?
        /// Name of the node.
        public let nodeName: String?
        /// Location of the node.
        public let location: String?
        /// Remote management mode.
        public let remoteMgmt: LinkRemoteManagement?
        /// Hub address.
        public let hub: String?
        /// Time of the last sync.
        public let lastSyncAt: String?
        /// Time the connection was established.
        public let connectedAt: String?
        /// Time the node was linked.
        public let linkedAt: String?
        /// Number of changes waiting to be sent.
        public let outbox: Int?
        /// Number of open conflicts.
        public let conflicts: Int?
        /// Last error.
        public let lastError: String?
        /// Pending link code.
        public let pendingCode: String?
        /// A link request is in progress.
        public let requesting: Bool?
        /// Limit of online checks.
        public let onlineLimit: Int?
        /// Online checks used today.
        public let checksToday: Int?
        /// Daily limit of online checks.
        public let checksLimit: Int?
        /// Locations allowed per check.
        public let locationsPerCheck: Int?
        /// Server channels are also sent locally.
        public let localNotifications: Bool?

        enum CodingKeys: String, CodingKey {
            case linked, connected, plan, location, hub, outbox, conflicts, requesting
            case accountID = "account_id"
            case nodeName = "node_name"
            case remoteMgmt = "remote_mgmt"
            case lastSyncAt = "last_sync_at"
            case connectedAt = "connected_at"
            case linkedAt = "linked_at"
            case lastError = "last_error"
            case pendingCode = "pending_code"
            case onlineLimit = "online_limit"
            case checksToday = "checks_today"
            case checksLimit = "checks_limit"
            case locationsPerCheck = "locations_per_check"
            case localNotifications = "local_notifications"
        }
    }

    /// Which version wins when resolving a sync conflict.
    public struct LinkConflictResolution: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Keep the server version (default).
        public static let server: LinkConflictResolution = "server"
        /// Keep the local version.
        public static let local: LinkConflictResolution = "local"
    }

    /// An open sync conflict with the local and the server version.
    public struct LinkConflict: Codable, Hashable, Sendable, Identifiable {
        /// Conflict ID.
        public let id: Int
        /// Kind of the affected object.
        public let entity: String?
        /// ID of the affected object.
        public let entityID: String?
        /// Name of the affected object.
        public let name: String?
        /// Local operation.
        public let localOp: String?
        /// Local version (free-form).
        public let local: JSONValue?
        /// Server version (free-form).
        public let server: JSONValue?
        /// Revision of the server version.
        public let serverRevision: Int?
        /// Creation time.
        public let createdAt: Date?

        enum CodingKeys: String, CodingKey {
            case id, entity, name, local, server
            case entityID = "entity_id"
            case localOp = "local_op"
            case serverRevision = "server_revision"
            case createdAt = "created_at"
        }
    }

    /// Sync settings (result of ``Node64/Link/updateSettings(localNotifications:)``).
    public struct LinkSettings: Codable, Hashable, Sendable {
        /// Server channels are also sent locally.
        public let localNotifications: Bool?

        enum CodingKeys: String, CodingKey {
            case localNotifications = "local_notifications"
        }
    }

    /// The central ipv64 API key of the node: account, plan and expiry. The key itself is never returned.
    public struct IPv64LinkAccount: Codable, Hashable, Sendable {
        /// A key is stored.
        public let keyStored: Bool?
        /// Account name.
        public let account: String?
        /// Account ID.
        public let accountID: Int?
        /// Plan.
        public let plan: String?
        /// Name of the key at ipv64.
        public let keyName: String?
        /// Time of the last check at ipv64.
        public let checkedAt: Date?
        /// Expiry of the key.
        public let expiresAt: Date?
        /// Days until the key expires.
        public let daysLeft: Int?

        enum CodingKeys: String, CodingKey {
            case account, plan
            case keyStored = "key_stored"
            case accountID = "account_id"
            case keyName = "key_name"
            case checkedAt = "checked_at"
            case expiresAt = "expires_at"
            case daysLeft = "days_left"
        }
    }
}
