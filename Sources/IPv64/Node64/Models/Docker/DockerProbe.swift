import Foundation

extension Node64 {
    /// Schema `DockerProbe`: result of testing a Docker host.
    public struct DockerProbe: Codable, Hashable, Sendable {
        /// Connection works.
        public let ok: Bool?
        /// Error message.
        public let error: String?
        /// Seen host key (SSH) or certificate (TLS), 64 hex; usable as `pinSHA256`.
        public let fingerprint: String?
        /// Fingerprint for comparing: SSH like `ssh-keygen` (`SHA256:…`), TLS with colons.
        public let fingerprintDisplay: String?
        /// TLS: certificate confirmed by the CA or system CA (no pin needed).
        public let trusted: Bool?
        /// Only the fingerprint was read: test again with it as `pinSHA256`.
        public let needConfirm: Bool?
        /// Seen fingerprint differs from the given pin.
        public let pinDiffers: Bool?
        /// `/info` of the Docker daemon.
        public let info: Info?
        /// Number of containers.
        public let containers: Int?
        /// Number of running containers.
        public let running: Int?
        /// Warning.
        public let warning: String?
        /// SSH: public part of the key in use (`authorized_keys` line).
        public let publicKey: String?

        /// Docker daemon information.
        public struct Info: Codable, Hashable, Sendable {
            /// Host name.
            public let name: String?
            /// Operating system.
            public let os: String?
            /// Docker version.
            public let version: String?
            /// Number of CPUs.
            public let ncpu: Int?
            /// Total memory in bytes.
            public let memTotal: Int?

            enum CodingKeys: String, CodingKey {
                case name, os, version, ncpu
                case memTotal = "mem_total"
            }
        }

        enum CodingKeys: String, CodingKey {
            case ok, error, fingerprint
            case fingerprintDisplay = "fingerprint_display"
            case trusted
            case needConfirm = "need_confirm"
            case pinDiffers = "pin_differs"
            case info, containers, running, warning
            case publicKey = "public_key"
        }
    }

    /// Schema `DockerCredentials`: which credentials are stored for a Docker host (never the keys themselves).
    public struct DockerCredentials: Codable, Hashable, Sendable {
        /// Private key (SSH or TLS client) is stored.
        public let key: Bool?
        /// TLS client certificate is stored.
        public let cert: Bool?
        /// CA of the Docker daemon is stored.
        public let ca: Bool?
        /// SSH: line for `~/.ssh/authorized_keys` on the Docker host.
        public let publicKey: String?

        enum CodingKeys: String, CodingKey {
            case key, cert, ca
            case publicKey = "public_key"
        }
    }

    /// Scope of "add all as check".
    public struct PVEAsCheckScope: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// All guests or containers (default).
        public static let guests: Self = "guests"
        /// All nodes (Proxmox only).
        public static let nodes: Self = "nodes"
    }

    /// Result of the `ascheck-all` endpoints.
    public struct PVEAsCheckAllResult: Codable, Hashable, Sendable {
        /// Newly created checks.
        public let added: Int?
        /// Number of failures.
        public let failed: Int?
        /// First error (only when `failed > 0`).
        public let error: String?
        /// i18n key of the first error.
        public let key: String?
    }
}
