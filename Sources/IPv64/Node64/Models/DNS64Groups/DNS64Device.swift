import Foundation

extension Node64 {
    /// Device seen in the last 24 hours. Schema `DNS64Device`.
    public struct DNS64Device: Codable, Hashable, Sendable {
        /// IP address.
        public let ip: String?
        /// Name from the router.
        public let name: String?
        /// MAC address from the neighbor table.
        public let mac: String?
        /// Name of the group.
        public let group: String?
        /// ID of the group.
        public let groupID: Int?
        /// Number of queries.
        public let queries: Int?
        /// Time of the last query.
        public let lastSeen: Date?

        enum CodingKeys: String, CodingKey {
            case ip, name, mac, group
            case groupID = "group_id"
            case queries
            case lastSeen = "last_seen"
        }
    }

    /// Device name of a zone with its current addresses (result of ``Node64/DNS64/Devices/names()``).
    public struct DNS64DeviceName: Codable, Hashable, Sendable {
        /// Fully qualified name, e.g. `tablet-lea.home.lan`.
        public let name: String?
        /// Current addresses.
        public let ips: [String]?
    }
}
