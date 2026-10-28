import Foundation

extension IPv64.HC2 {
    /// Endpoints for Node64 nodes (`/hc2/nodes` and `/node64`).
    public struct Nodes: Sendable {
        let client: IPv64

        /// A Node64 container announces itself (node overview).
        ///
        /// Called by the Node64 container on start, after changes and every 15 minutes. The server expects the
        /// header `X-Node64-Node` to equal `node_id`; if the node was removed from the overview it answers
        /// `403 node_removed`.
        ///
        /// `POST /node64/hello`
        public func hello(_ hello: Node64HelloInput) async throws {
            try await client.sendWithoutContent(Request(
                .post, "/node64/hello",
                body: .json(hello),
                headers: ["X-Node64-Node": hello.nodeID]
            ))
        }

        /// All Node64 containers of the account (node overview).
        ///
        /// The API documents no response schema; the decoded JSON body is returned as is
        /// (`JSONValue.null` for an empty body).
        ///
        /// `GET /node64/nodes`
        public func containers() async throws -> JSONValue {
            let (data, _) = try await client.perform(Request(.get, "/node64/nodes"))
            if data.isEmpty { return .null }
            do {
                return try IPv64Coding.makeDecoder().decode(JSONValue.self, from: data)
            } catch {
                throw IPv64Error.decoding(error, body: data)
            }
        }

        /// Lists nodes.
        ///
        /// `GET /hc2/nodes`
        public func list() async throws -> [HC2Node] {
            try await client.send(Request(.get, "/hc2/nodes"))
        }

        /// Links a node by code.
        ///
        /// The node shows a code under "ipv64 link"; after redemption it fetches its token itself.
        ///
        /// - Parameters:
        ///   - code: Code of the node (8 characters, e.g. `ABCD-EFGH`).
        ///   - location: Location (free-form).
        ///   - remoteManagement: Remote management: `off`, `read` or `full` (default `full`).
        ///
        /// `POST /hc2/nodes/link`
        public func link(
            code: String,
            location: String? = nil,
            remoteManagement: HC2RemoteManagement? = nil
        ) async throws -> HC2NodeLinkResult {
            struct Body: Encodable, Sendable {
                let code: String
                let location: String?
                let remoteManagement: HC2RemoteManagement?

                enum CodingKeys: String, CodingKey {
                    case code, location
                    case remoteManagement = "remote_mgmt"
                }
            }
            let body = Body(code: code, location: location, remoteManagement: remoteManagement)
            return try await client.send(Request(.post, "/hc2/nodes/link", body: .json(body)))
        }

        /// A node with its checks.
        ///
        /// - Parameter nodeID: Node ID (32 characters).
        ///
        /// `GET /hc2/nodes/{node_id}`
        public func get(_ nodeID: String) async throws -> HC2NodeDetail {
            try await client.send(Request(.get, "/hc2/nodes/\(nodeID)"))
        }

        /// Renames a node or changes its location and remote management.
        ///
        /// `PATCH /hc2/nodes/{node_id}`
        public func update(
            _ nodeID: String,
            name: String? = nil,
            location: String? = nil,
            remoteManagement: HC2RemoteManagement? = nil
        ) async throws -> HC2Node {
            struct Body: Encodable, Sendable {
                let name: String?
                let location: String?
                let remoteManagement: HC2RemoteManagement?

                enum CodingKeys: String, CodingKey {
                    case name, location
                    case remoteManagement = "remote_mgmt"
                }
            }
            let body = Body(name: name, location: location, remoteManagement: remoteManagement)
            return try await client.send(Request(.patch, "/hc2/nodes/\(nodeID)", body: .json(body)))
        }

        /// Unlinks a node and revokes its token. The node keeps running standalone.
        ///
        /// - Parameters:
        ///   - nodeID: Node ID.
        ///   - keepChecks: Keep checks with a public target as online checks (server default `true`).
        ///
        /// `DELETE /hc2/nodes/{node_id}`
        public func unlink(_ nodeID: String, keepChecks: Bool? = nil) async throws -> HC2NodeUnlinkResult {
            struct Body: Encodable, Sendable {
                let keepChecks: Bool?

                enum CodingKeys: String, CodingKey {
                    case keepChecks = "keep_checks"
                }
            }
            return try await client.send(
                Request(.delete, "/hc2/nodes/\(nodeID)", body: .json(Body(keepChecks: keepChecks)))
            )
        }

        /// The latest commands sent to a node.
        ///
        /// - Parameters:
        ///   - nodeID: Node ID.
        ///   - limit: At most 200.
        ///
        /// `GET /hc2/nodes/{node_id}/commands`
        public func commands(_ nodeID: String, limit: Int? = nil) async throws -> [HC2Command] {
            try await client.send(Request(.get, "/hc2/nodes/\(nodeID)/commands", query: [QueryItem("limit", limit)]))
        }

        /// Sends a command to a node. The node only accepts commands if its remote management allows it.
        ///
        /// - Parameters:
        ///   - nodeID: Node ID.
        ///   - name: Command: `run_check`, `repair`, `pause`, `resume`, `resolve_conflict`.
        ///   - arguments: Command arguments.
        ///
        /// `POST /hc2/nodes/{node_id}/commands`
        public func sendCommand(
            _ nodeID: String,
            name: HC2CommandName,
            arguments: HC2CommandArguments? = nil
        ) async throws -> HC2Command {
            struct Body: Encodable, Sendable {
                let name: HC2CommandName
                let args: HC2CommandArguments?
            }
            return try await client.send(
                Request(.post, "/hc2/nodes/\(nodeID)/commands", body: .json(Body(name: name, args: arguments)))
            )
        }
    }
}

/// Arguments of a node command.
public struct HC2CommandArguments: Encodable, Hashable, Sendable {
    /// Check token (`run_check`, `pause`, `resume`).
    public var token: String?
    /// Conflict number (`resolve_conflict`).
    public var id: Int?
    /// Which side wins (`resolve_conflict`).
    public var keep: HC2ConflictResolution?

    /// Creates command arguments.
    public init(token: String? = nil, id: Int? = nil, keep: HC2ConflictResolution? = nil) {
        self.token = token
        self.id = id
        self.keep = keep
    }
}

/// Request body of ``IPv64/HC2/Nodes/hello(_:)``.
public struct Node64HelloInput: Encodable, Hashable, Sendable {
    /// Node ID.
    public var nodeID: String
    /// Name.
    public var name: String?
    /// Location.
    public var location: String?
    /// Version.
    public var version: String?
    /// OS and architecture.
    public var osArch: String?
    /// Mode.
    public var mode: String?
    /// Enabled modules.
    public var modules: [String]?
    /// Features of the node.
    public var features: Features?

    /// Features of a Node64 container.
    public struct Features: Encodable, Hashable, Sendable {
        /// Linked for healthcheck sync.
        public var hcSyncLinked: Bool?
        /// Node ID at the hub.
        public var hubNodeID: String?
        /// Honeypot sensor ID.
        public var honeypotSensorID: String?
        /// CDN64 tunnel.
        public var cdn64Tunnel: String?
        /// DynDNS module active.
        public var dyndns: Bool?

        /// Creates the features.
        public init(
            hcSyncLinked: Bool? = nil,
            hubNodeID: String? = nil,
            honeypotSensorID: String? = nil,
            cdn64Tunnel: String? = nil,
            dyndns: Bool? = nil
        ) {
            self.hcSyncLinked = hcSyncLinked
            self.hubNodeID = hubNodeID
            self.honeypotSensorID = honeypotSensorID
            self.cdn64Tunnel = cdn64Tunnel
            self.dyndns = dyndns
        }

        enum CodingKeys: String, CodingKey {
            case hcSyncLinked = "hc_sync_linked"
            case hubNodeID = "hub_node_id"
            case honeypotSensorID = "honeypot_sensor_id"
            case cdn64Tunnel = "cdn64_tunnel"
            case dyndns
        }
    }

    /// Creates the body.
    public init(
        nodeID: String,
        name: String? = nil,
        location: String? = nil,
        version: String? = nil,
        osArch: String? = nil,
        mode: String? = nil,
        modules: [String]? = nil,
        features: Features? = nil
    ) {
        self.nodeID = nodeID
        self.name = name
        self.location = location
        self.version = version
        self.osArch = osArch
        self.mode = mode
        self.modules = modules
        self.features = features
    }

    enum CodingKeys: String, CodingKey {
        case nodeID = "node_id"
        case name, location, version
        case osArch = "os_arch"
        case mode, modules, features
    }
}

/// Result of ``IPv64/HC2/Nodes/link(code:location:remoteManagement:)``.
public struct HC2NodeLinkResult: Codable, Hashable, Sendable {
    /// The code was accepted.
    public let accepted: Bool?
    /// Details.
    public let detail: String?
}

/// Result of ``IPv64/HC2/Nodes/unlink(_:keepChecks:)``.
public struct HC2NodeUnlinkResult: Codable, Hashable, Sendable {
    /// The node was unlinked.
    public let unlinked: Bool?
    /// Number of checks continued as online checks.
    public let checksKeptOnline: Int?
    /// Number of checks deleted.
    public let checksDeleted: Int?

    enum CodingKeys: String, CodingKey {
        case unlinked
        case checksKeptOnline = "checks_kept_online"
        case checksDeleted = "checks_deleted"
    }
}
