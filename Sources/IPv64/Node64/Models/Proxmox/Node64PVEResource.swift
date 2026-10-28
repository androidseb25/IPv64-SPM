import Foundation

extension Node64 {
    /// Type of a ``PVEResource``.
    public struct PVEResourceType: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Proxmox node.
        public static let node: Self = "node"
        /// QEMU virtual machine.
        public static let qemu: Self = "qemu"
        /// LXC container.
        public static let lxc: Self = "lxc"
        /// Docker container.
        public static let docker: Self = "docker"
    }

    /// State of a ``PVEResource``.
    public struct PVEResourceState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let running: Self = "running"
        public static let stopped: Self = "stopped"
        public static let paused: Self = "paused"
        public static let suspended: Self = "suspended"
        public static let backup: Self = "backup"
        public static let locked: Self = "locked"
        public static let online: Self = "online"
        public static let offline: Self = "offline"
        public static let unknown: Self = "unknown"
        public static let error: Self = "error"
    }

    /// Schema `PVEResource`: a node, guest or Docker container from the last query.
    public struct PVEResource: Codable, Hashable, Sendable {
        /// `node/<name>`, `qemu/<vmid>`, `lxc/<vmid>` or `docker/<name>`.
        public let key: String?
        /// Type.
        public let type: PVEResourceType?
        /// Node name.
        public let node: String?
        /// VM ID.
        public let vmid: Int?
        /// Name.
        public let name: String?
        /// State.
        public let state: PVEResourceState?
        /// Raw status.
        public let status: String?
        /// QMP status.
        public let qmp: String?
        /// Lock.
        public let lock: String?
        /// Tags.
        public let tags: [String]?
        /// HA state.
        public let haState: String?
        /// Is a template.
        public let template: Bool?
        /// CPU share 0..1 (Docker: relative to the CPU limit or host cores).
        public let cpu: Double?
        /// Number of CPUs.
        public let maxCPU: Double?
        /// Memory in bytes.
        public let mem: Int?
        /// Memory limit in bytes.
        public let maxMem: Int?
        /// Disk usage in bytes.
        public let disk: Int?
        /// Disk size in bytes.
        public let maxDisk: Int?
        /// Uptime in seconds.
        public let uptime: Int?
        /// Network in, bytes per second.
        public let netIn: Double?
        /// Network out, bytes per second.
        public let netOut: Double?
        /// Disk read, bytes per second.
        public let diskRead: Double?
        /// Disk write, bytes per second.
        public let diskWrite: Double?
        /// Restarted since the last query.
        public let restarted: Bool?
        /// In a bad state.
        public let bad: Bool?
        /// Excluded (template, tag `nomonitor`; Docker: label `node64.nomonitor=true`).
        public let excluded: Bool?
        /// Muted.
        public let muted: Bool?
        /// Monitored as a healthcheck.
        public let asCheck: Bool?
        /// Token of the check.
        public let checkToken: String?
        /// Docker only: container ID (12 characters).
        public let containerID: String?
        /// Docker only: image.
        public let image: String?
        /// Docker only: container healthcheck.
        public let health: DockerHealth?
        /// Docker only: restarts by Docker.
        public let restartCount: Int?
        /// Docker only: exit code.
        public let exitCode: Int?
        /// Docker only: killed by the OOM killer.
        public let oomKilled: Bool?
        /// Docker only: creation time (Unix).
        public let created: Int?
        /// Docker only: published ports, e.g. `8080->80/tcp`.
        public let ports: [String]?
        /// Docker only: labels (at most 64).
        public let labels: [String: String]?
        /// Docker only, with state `error`: the cause.
        public let detail: DockerContainerDetail?

        enum CodingKeys: String, CodingKey {
            case key, type, node, vmid, name, state, status, qmp, lock, tags
            case haState = "ha_state"
            case template, cpu
            case maxCPU = "max_cpu"
            case mem
            case maxMem = "max_mem"
            case disk
            case maxDisk = "max_disk"
            case uptime
            case netIn = "net_in"
            case netOut = "net_out"
            case diskRead = "disk_read"
            case diskWrite = "disk_write"
            case restarted, bad, excluded, muted
            case asCheck = "as_check"
            case checkToken = "check_token"
            case containerID = "container_id"
            case image, health
            case restartCount = "restart_count"
            case exitCode = "exit_code"
            case oomKilled = "oom_killed"
            case created, ports, labels, detail
        }
    }

    /// Result of the `resources` endpoints: the system and its nodes and guests (or containers).
    public struct PVEResources: Codable, Hashable, Sendable {
        /// The system.
        public let system: PVESystem?
        /// Resources from the last query.
        public let resources: [PVEResource]?
    }

    /// Time range of ``PVESeries``.
    public struct PVESeriesRange: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Last hour.
        public static let hour: Self = "1h"
        /// Last 24 hours (default).
        public static let day: Self = "24h"
        /// Last 7 days.
        public static let week: Self = "7d"
        /// Last 30 days.
        public static let month: Self = "30d"
    }

    /// Result of the `series` endpoints.
    public struct PVESeries: Codable, Hashable, Sendable {
        /// Key of the node, guest or container.
        public let key: String?
        /// Requested range.
        public let range: String?
        /// Resolution in seconds.
        public let stepSeconds: Int?
        /// Start of the range.
        public let from: Date?
        /// End of the range.
        public let to: Date?
        /// Data points.
        public let points: [PVEPoint]?

        enum CodingKeys: String, CodingKey {
            case key, range
            case stepSeconds = "step_seconds"
            case from, to, points
        }
    }

    /// Schema `PVEPoint`: one data point of a series.
    public struct PVEPoint: Codable, Hashable, Sendable {
        /// Time.
        public let t: Date?
        /// CPU in percent.
        public let cpu: Double?
        /// Peak CPU.
        public let cpuMax: Double?
        /// Memory in percent.
        public let mem: Double?
        /// Disk in percent (`nil` if unknown).
        public let disk: Double?
        /// Network in, bytes per second.
        public let netIn: Double?
        /// Network out, bytes per second.
        public let netOut: Double?
        /// Disk read, bytes per second.
        public let diskRead: Double?
        /// Disk write, bytes per second.
        public let diskWrite: Double?

        enum CodingKeys: String, CodingKey {
            case t, cpu
            case cpuMax = "cpu_max"
            case mem, disk
            case netIn = "net_in"
            case netOut = "net_out"
            case diskRead = "disk_read"
            case diskWrite = "disk_write"
        }
    }
}
