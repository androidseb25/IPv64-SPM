import Foundation

extension Node64 {
    /// State of a cluster member.
    public struct ClusterMemberState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// The member takes part in the group.
        public static let active: ClusterMemberState = "active"
        /// The member is suspended (see ``ClusterMember/reason``).
        public static let suspended: ClusterMemberState = "suspended"
    }

    /// Reason why a member is suspended.
    public struct ClusterSuspensionReason: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `account_changed`
        public static let accountChanged: ClusterSuspensionReason = "account_changed"
        /// `account_mismatch`
        public static let accountMismatch: ClusterSuspensionReason = "account_mismatch"
        /// `identity_changed`
        public static let identityChanged: ClusterSuspensionReason = "identity_changed"
        /// `tls_binding`
        public static let tlsBinding: ClusterSuspensionReason = "tls_binding"
        /// `version_too_old`
        public static let versionTooOld: ClusterSuspensionReason = "version_too_old"
    }

    /// A member of the local cluster.
    public struct ClusterMember: Codable, Hashable, Sendable, Identifiable {
        /// Node ID of the member.
        public let nodeID: String
        /// Name of the member.
        public let name: String?
        /// Address of the member.
        public let url: String?
        /// The member is online.
        public let online: Bool?
        /// The member is linked to ipv64.
        public let linked: Bool?
        /// Software version of the member.
        public let version: String?
        /// Time the member was last seen.
        public let lastSeen: Date?
        /// Last error.
        public let lastError: String?
        /// Time the member was added.
        public let addedAt: Date?
        /// State of the member.
        public let state: ClusterMemberState?
        /// Reason for a suspension.
        public let reason: ClusterSuspensionReason?
        /// Areas (`module/area`) switched on there; `nil` for an older version that does not report them.
        public let sync: [String]?

        public var id: String { nodeID }

        enum CodingKeys: String, CodingKey {
            case name, url, online, linked, version, state, reason, sync
            case nodeID = "node_id"
            case lastSeen = "last_seen"
            case lastError = "last_error"
            case addedAt = "added_at"
        }
    }

    /// An area of a syncable module.
    public struct ClusterSyncItem: Codable, Hashable, Sendable, Identifiable {
        /// Area ID.
        public let id: String
        /// i18n key of the title.
        public let titleKey: String?
        /// Sync of this area is switched on.
        public let enabled: Bool?

        enum CodingKeys: String, CodingKey {
            case id, enabled
            case titleKey = "title_key"
        }
    }

    /// A module whose data can be synced, with its switches on this node.
    public struct ClusterSyncModule: Codable, Hashable, Sendable, Identifiable {
        /// Module ID, e.g. `healthchecks`.
        public let id: String
        /// i18n key of the title.
        public let titleKey: String?
        /// The module runs on this node.
        public let available: Bool?
        /// Sync of the module is switched on.
        public let enabled: Bool?
        /// Areas of the module.
        public let items: [ClusterSyncItem]?

        enum CodingKeys: String, CodingKey {
            case id, available, enabled, items
            case titleKey = "title_key"
        }
    }

    /// The local cluster: members, forwarding node, open code and sync switches.
    public struct ClusterGroup: Codable, Hashable, Sendable {
        /// ipv64 account ID.
        public let accountID: Int?
        /// This node is linked to ipv64.
        public let linked: Bool?
        /// Node that forwards changes of nodes without sync to ipv64.
        public let forwarder: String?
        /// This node is the forwarder.
        public let forwarderSelf: Bool?
        /// Open pairing code.
        public let code: String?
        /// Expiry of the open code.
        public let codeExpires: Date?
        /// Members with their state.
        public let members: [ClusterMember]?
        /// Syncable modules with the switches on this node.
        public let syncModules: [ClusterSyncModule]?
        /// Own HTTPS port of this node, `0` = none (the cluster then uses the HTTP port, which also speaks TLS).
        public let httpsPort: Int?

        enum CodingKeys: String, CodingKey {
            case linked, forwarder, code, members
            case accountID = "account_id"
            case forwarderSelf = "forwarder_self"
            case codeExpires = "code_expires"
            case syncModules = "sync_modules"
            case httpsPort = "https_port"
        }
    }

    /// Pairing code for another node.
    public struct ClusterCode: Codable, Hashable, Sendable {
        /// The code (valid for 10 minutes, once).
        public let code: String?
        /// Expiry time.
        public let expires: Date?
    }

    /// New sync switches (result of ``Node64/Cluster/setSync(module:item:enabled:)``).
    public struct ClusterSyncState: Codable, Hashable, Sendable {
        /// Syncable modules with the switches on this node.
        public let syncModules: [ClusterSyncModule]?

        enum CodingKeys: String, CodingKey {
            case syncModules = "sync_modules"
        }
    }
}
