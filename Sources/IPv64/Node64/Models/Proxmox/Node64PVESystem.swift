import Foundation

extension Node64 {
    /// Kind of a monitored system.
    public struct PVESystemKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Proxmox VE.
        public static let pve: Self = "pve"
        /// Proxmox Backup Server.
        public static let pbs: Self = "pbs"
        /// Docker host.
        public static let docker: Self = "docker"
    }

    /// Filter for ``Node64/HC/Proxmox/Systems/list(kind:)``.
    public struct PVEKindFilter: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Only Proxmox systems (default).
        public static let pve: Self = "pve"
        /// Only Proxmox Backup Servers.
        public static let pbs: Self = "pbs"
        /// Only Docker hosts.
        public static let docker: Self = "docker"
        /// All systems.
        public static let all: Self = "all"
    }

    /// State of a monitored system.
    public struct PVESystemState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Everything fine.
        public static let ok: Self = "ok"
        /// Warning.
        public static let warn: Self = "warn"
        /// Down.
        public static let down: Self = "down"
        /// Query error.
        public static let error: Self = "error"
        /// Monitoring switched off.
        public static let off: Self = "off"
        /// No query yet.
        public static let pending: Self = "pending"
    }

    /// Schema `PVESystem`: a Proxmox VE system (single node or cluster) or a Docker host with its state.
    ///
    /// The token secret is never returned. For Docker hosts `addresses` holds the socket,
    /// there is no `tokenID` or `pinSHA256`, and "guests" are containers.
    public struct PVESystem: Codable, Hashable, Sendable, Identifiable {
        /// ID of the system.
        public let id: Int
        /// Kind of the system.
        public let kind: PVESystemKind?
        /// Name.
        public let name: String?
        /// Addresses, e.g. `https://pve1.lan:8006`.
        public let addresses: [String]?
        /// API token ID, e.g. `node64@pve!monitor`.
        public let tokenID: String?
        /// Pinned certificate fingerprint (64 hex characters); empty uses the system CA.
        public let pinSHA256: String?
        /// Query interval in seconds (15 to 300).
        public let interval: Int?
        /// Monitoring is switched on.
        public let enabled: Bool?
        /// Creation time.
        public let created: Date?
        /// Cluster-wide identifier (32 hex characters).
        public let uid: String?
        /// Node that created the system; absent means this node.
        public let home: String?
        /// A secret is stored and readable.
        public let hasSecret: Bool?
        /// State from the last query.
        public let state: PVESystemState?
        /// Error of the last query.
        public let error: String?
        /// Software version.
        public let version: String?
        /// Cluster name.
        public let cluster: String?
        /// Cluster has quorum.
        public let quorate: Bool?
        /// Address that answered the last query.
        public let address: String?
        /// Time of the last query.
        public let lastPoll: Date?
        /// Number of nodes.
        public let nodes: Int?
        /// Number of nodes online.
        public let nodesOnline: Int?
        /// Number of guests (Docker: containers).
        public let guests: Int?
        /// Number of running guests.
        public let guestsRunning: Int?
        /// Number of guests in a bad state.
        public let guestsBad: Int?
        /// Docker hosts via SSH/TLS: which credentials are stored (never the keys).
        public let credentials: DockerCredentials?
        /// Proxmox VE only: storages from the last query.
        public let storages: [Storage]?
        /// Proxmox Backup Server only: datastores, services, update, failed tasks (free-form object in the spec).
        public let pbs: JSONValue?

        /// Storage of a Proxmox VE system.
        public struct Storage: Codable, Hashable, Sendable {
            /// Storage name.
            public let storage: String?
            /// Node.
            public let node: String?
            /// Shared storage.
            public let shared: Bool?
            /// Storage type.
            public let type: String?
            /// Content types.
            public let content: String?
            /// Status.
            public let status: String?
            /// Total bytes.
            public let total: Int?
            /// Used bytes.
            public let used: Int?
        }

        enum CodingKeys: String, CodingKey {
            case id, kind, name, addresses
            case tokenID = "token_id"
            case pinSHA256 = "pin_sha256"
            case interval, enabled, created, uid, home
            case hasSecret = "has_secret"
            case state, error, version, cluster, quorate, address
            case lastPoll = "last_poll"
            case nodes
            case nodesOnline = "nodes_online"
            case guests
            case guestsRunning = "guests_running"
            case guestsBad = "guests_bad"
            case credentials, storages, pbs
        }
    }

    /// Schema `PVESystemInput`: body for creating or partially updating a system.
    ///
    /// The secret is required on create; on update an empty secret keeps the stored one.
    public struct PVESystemInput: Encodable, Hashable, Sendable {
        /// `pve` (default) or `pbs`; only on create and probe (Docker hosts use `/healthchecks/docker`).
        public var kind: PVESystemKind?
        /// Name.
        public var name: String?
        /// Addresses.
        public var addresses: [String]?
        /// API token ID.
        public var tokenID: String?
        /// API token secret (write only).
        public var secret: String?
        /// Pinned certificate fingerprint (64 hex characters).
        public var pinSHA256: String?
        /// Query interval in seconds (15 to 300, default 30).
        public var interval: Int?
        /// Switch monitoring on or off (default on); toggling pauses or starts the system's checks.
        public var enabled: Bool?
        /// Docker only: private SSH or TLS client key (PEM, write only, secret); empty keeps the stored one.
        public var privateKey: String?
        /// Docker (https) only: TLS client certificate (PEM); `""` removes certificate and key.
        public var cert: String?
        /// Docker (https) only: CA of the Docker daemon (PEM); `""` removes it.
        public var ca: String?
        /// Docker (ssh) only: generate and store a new ed25519 key; the public part appears in `credentials.publicKey`.
        public var generateKey: Bool?

        public init(
            kind: PVESystemKind? = nil,
            name: String? = nil,
            addresses: [String]? = nil,
            tokenID: String? = nil,
            secret: String? = nil,
            pinSHA256: String? = nil,
            interval: Int? = nil,
            enabled: Bool? = nil,
            privateKey: String? = nil,
            cert: String? = nil,
            ca: String? = nil,
            generateKey: Bool? = nil
        ) {
            self.kind = kind
            self.privateKey = privateKey
            self.cert = cert
            self.ca = ca
            self.generateKey = generateKey
            self.name = name
            self.addresses = addresses
            self.tokenID = tokenID
            self.secret = secret
            self.pinSHA256 = pinSHA256
            self.interval = interval
            self.enabled = enabled
        }

        enum CodingKeys: String, CodingKey {
            case kind, name, addresses
            case tokenID = "token_id"
            case secret
            case pinSHA256 = "pin_sha256"
            case interval, enabled
            case privateKey = "private_key"
            case cert, ca
            case generateKey = "generate_key"
        }
    }

    /// Schema `PVEProbe`: result of a connection test.
    public struct PVEProbe: Codable, Hashable, Sendable {
        /// Connection works.
        public let ok: Bool?
        /// Error message.
        public let error: String?
        /// Software version.
        public let version: String?
        /// Cluster name.
        public let cluster: String?
        /// Node names.
        public let nodes: [String]?
        /// Number of guests.
        public let guests: Int?
        /// SHA-256 fingerprint of the certificate (also given when it is untrusted).
        public let certSHA256: String?
        /// Subject of the certificate.
        public let certSubject: String?
        /// The certificate is trusted.
        public let certTrusted: Bool?
        /// Warning about missing permissions of the token.
        public let permWarning: String?

        enum CodingKeys: String, CodingKey {
            case ok, error, version, cluster, nodes, guests
            case certSHA256 = "cert_sha256"
            case certSubject = "cert_subject"
            case certTrusted = "cert_trusted"
            case permWarning = "perm_warning"
        }
    }
}
