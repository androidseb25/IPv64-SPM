import Foundation

extension Node64 {
    /// Kind (overall state) of a Docker container.
    public struct DockerContainerKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let running: Self = "running"
        public static let stopped: Self = "stopped"
        public static let paused: Self = "paused"
        public static let restarting: Self = "restarting"
        /// A check without a container.
        public static let missing: Self = "missing"
        /// Another node or another Docker host.
        public static let remote: Self = "remote"
        /// Socket unreachable.
        public static let unknown: Self = "unknown"
    }

    /// Healthcheck state of a Docker container.
    public struct DockerHealth: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let healthy: Self = "healthy"
        public static let unhealthy: Self = "unhealthy"
        public static let starting: Self = "starting"
    }

    /// State of a container as the rules see it.
    public struct DockerMonitorState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let running: Self = "running"
        public static let stopped: Self = "stopped"
        public static let paused: Self = "paused"
        public static let error: Self = "error"
        public static let unknown: Self = "unknown"
    }

    /// Cause of a container problem.
    public struct DockerContainerDetail: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        public static let unhealthy: Self = "unhealthy"
        public static let restarting: Self = "restarting"
        public static let exited: Self = "exited"
        public static let oom: Self = "oom"
        public static let dead: Self = "dead"
    }

    /// Result of ``Node64/HC/Docker/containers()``.
    public struct DockerContainers: Codable, Hashable, Sendable {
        /// Docker host, e.g. `unix:///var/run/docker.sock`.
        public let host: String?
        /// The Docker socket is reachable.
        public let socket: Bool?
        /// Error with a hint when the socket is missing.
        public let error: String?
        /// Containers.
        public let containers: [DockerContainer]?
        /// Docker host of the monitoring; absent if there is none.
        public let systemID: Int?
        /// Values come from running monitoring.
        public let monitored: Bool?

        enum CodingKeys: String, CodingKey {
            case host, socket, error, containers
            case systemID = "system_id"
            case monitored
        }
    }

    /// A Docker container with monitoring values and its Docker check.
    public struct DockerContainer: Codable, Hashable, Sendable {
        /// Name.
        public let name: String?
        /// Overall kind.
        public let kind: DockerContainerKind?
        /// Container healthcheck.
        public let health: DockerHealth?
        /// Container ID.
        public let id: String?
        /// Image.
        public let image: String?
        /// Docker state, e.g. `running`.
        public let state: String?
        /// Creation time.
        public let created: Date?
        /// Published ports, e.g. `8080->80/tcp`.
        public let ports: [String]?
        /// Check of this container; `nil` without a check.
        public let check: DockerContainerCheck?
        /// Key, e.g. `docker/web`.
        public let key: String?
        /// State as the rules see it.
        public let monitor: DockerMonitorState?
        /// Cause of a problem.
        public let detail: DockerContainerDetail?
        /// In a bad state or container missing.
        public let bad: Bool?
        /// Monitored as a check.
        public let asCheck: Bool?
        /// Excluded by the label `node64.nomonitor=true`.
        public let excluded: Bool?
        /// Muted.
        public let muted: Bool?
        /// CPU share 0..1 relative to `cpus`.
        public let cpu: Double?
        /// CPU limit or host cores.
        public let cpus: Double?
        /// Memory in bytes (without inactive file cache).
        public let mem: Int?
        /// Memory limit or host RAM in bytes.
        public let maxMem: Int?
        /// Network in, bytes per second.
        public let netIn: Double?
        /// Network out, bytes per second.
        public let netOut: Double?
        /// Disk read, bytes per second.
        public let diskRead: Double?
        /// Disk write, bytes per second.
        public let diskWrite: Double?
        /// Uptime in seconds.
        public let uptime: Int?
        /// Restarts by Docker.
        public let restartCount: Int?
        /// Exit code.
        public let exitCode: Int?

        enum CodingKeys: String, CodingKey {
            case name, kind, health, id, image, state, created, ports, check, key, monitor, detail, bad
            case asCheck = "as_check"
            case excluded, muted, cpu, cpus, mem
            case maxMem = "max_mem"
            case netIn = "net_in"
            case netOut = "net_out"
            case diskRead = "disk_read"
            case diskWrite = "disk_write"
            case uptime
            case restartCount = "restart_count"
            case exitCode = "exit_code"
        }
    }

    /// The Docker check attached to a ``DockerContainer``.
    public struct DockerContainerCheck: Codable, Hashable, Sendable {
        /// Token of the check.
        public let token: String?
        /// Name of the check.
        public let name: String?
        /// State of the check.
        public let state: String?
        /// Message of the check.
        public let message: String?
    }
}
