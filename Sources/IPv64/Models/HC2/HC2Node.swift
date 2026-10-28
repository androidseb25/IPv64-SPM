import Foundation

/// A linked Node64 node.
public struct HC2Node: Codable, Hashable, Sendable, Identifiable {
    /// Node ID (32 characters).
    public let nodeID: String
    /// Name.
    public let name: String?
    /// Location.
    public let location: String?
    /// Node version.
    public let version: String?
    /// Time zone.
    public let timezone: String?
    /// Enabled modules.
    public let modules: [String]?
    /// Remote management: `off`, `read` or `full`.
    public let remoteMgmt: HC2RemoteManagement?
    /// Currently online.
    public let online: Bool?
    /// Last contact.
    public let lastSeen: Date?
    /// Last synchronisation.
    public let lastSync: Date?
    /// Number of pending outbox entries.
    public let outboxSize: Int?
    /// Number of sync conflicts.
    public let conflicts: Int?
    /// Hub the node is connected to.
    public let hub: String?
    /// Time of linking.
    public let linkedAt: Date?

    /// Stable identity: the node ID.
    public var id: String { nodeID }

    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case name, location, version, timezone, modules
        case remoteMgmt = "remote_mgmt"
        case online
        case lastSeen = "last_seen"
        case lastSync = "last_sync"
        case outboxSize = "outbox_size"
        case conflicts, hub
        case linkedAt = "linked_at"
    }
}

/// A node with its checks (flattened `Hc2Node` plus `checks`).
public struct HC2NodeDetail: Codable, Hashable, Sendable, Identifiable {
    /// Node ID (32 characters).
    public let nodeID: String
    /// Name.
    public let name: String?
    /// Location.
    public let location: String?
    /// Node version.
    public let version: String?
    /// Time zone.
    public let timezone: String?
    /// Enabled modules.
    public let modules: [String]?
    /// Remote management: `off`, `read` or `full`.
    public let remoteMgmt: HC2RemoteManagement?
    /// Currently online.
    public let online: Bool?
    /// Last contact.
    public let lastSeen: Date?
    /// Last synchronisation.
    public let lastSync: Date?
    /// Number of pending outbox entries.
    public let outboxSize: Int?
    /// Number of sync conflicts.
    public let conflicts: Int?
    /// Hub the node is connected to.
    public let hub: String?
    /// Time of linking.
    public let linkedAt: Date?
    /// Checks of this node.
    public let checks: [HC2Check]?

    /// Stable identity: the node ID.
    public var id: String { nodeID }

    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case name, location, version, timezone, modules
        case remoteMgmt = "remote_mgmt"
        case online
        case lastSeen = "last_seen"
        case lastSync = "last_sync"
        case outboxSize = "outbox_size"
        case conflicts, hub
        case linkedAt = "linked_at"
        case checks
    }
}

/// A command sent to a node.
public struct HC2Command: Codable, Hashable, Sendable, Identifiable {
    /// Command number.
    public let commandID: Int
    /// Node ID.
    public let nodeID: String?
    /// Command name.
    public let name: String?
    /// Command arguments.
    public let args: JSONValue?
    /// Creation time.
    public let createdAt: Date?
    /// Completion time.
    public let doneAt: Date?
    /// The command succeeded.
    public let ok: Bool?
    /// Result of the command.
    public let output: JSONValue?

    /// Stable identity: the command number.
    public var id: Int { commandID }

    enum CodingKeys: String, CodingKey {
        case commandID = "command_id"
        case nodeID = "node_id"
        case name, args
        case createdAt = "created_at"
        case doneAt = "done_at"
        case ok, output
    }
}
