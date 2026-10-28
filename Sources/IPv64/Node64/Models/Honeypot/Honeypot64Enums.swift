import Foundation

extension Node64 {
    /// Honeypot service profile. Open enum.
    public struct Honeypot64Profile: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Minimal.
        public static let minimal: Self = "minimal"
        /// Standard (default).
        public static let standard: Self = "standard"
        /// All services.
        public static let full: Self = "full"
        /// Own selection in `services`.
        public static let custom: Self = "custom"
    }

    /// Sensor that recorded an event. Open enum.
    public struct Honeypot64Source: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Trap service.
        public static let honeypot: Self = "honeypot"
        /// Log sensor.
        public static let log: Self = "log"
        /// Syslog receiver.
        public static let syslog: Self = "syslog"
    }

    /// Decoy page of an http/https trap. Open enum.
    public struct Honeypot64DecoyPage: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Generic.
        public static let generic: Self = "generic"
        /// WordPress login.
        public static let wpLogin: Self = "wp-login"
        /// phpMyAdmin.
        public static let phpMyAdmin: Self = "phpmyadmin"
        /// Admin page.
        public static let admin: Self = "admin"
    }

    /// Log format of a log file (empty or `auto` = automatic). Open enum.
    public struct Honeypot64LogFormat: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Automatic.
        public static let none: Self = ""
        /// Automatic.
        public static let auto: Self = "auto"
        /// Syslog.
        public static let syslog: Self = "syslog"
        /// nginx.
        public static let nginx: Self = "nginx"
        /// Apache.
        public static let apache: Self = "apache"
        /// Caddy.
        public static let caddy: Self = "caddy"
        /// Nextcloud.
        public static let nextcloud: Self = "nextcloud"
        /// Vaultwarden.
        public static let vaultwarden: Self = "vaultwarden"
        /// Gitea.
        public static let gitea: Self = "gitea"
        /// Proxmox.
        public static let proxmox: Self = "proxmox"
        /// Home Assistant.
        public static let homeAssistant: Self = "homeassistant"
    }

    /// Transport protocol of a catalog entry. Open enum.
    public struct Honeypot64Protocol: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// TCP.
        public static let tcp: Self = "tcp"
        /// UDP.
        public static let udp: Self = "udp"
    }

    /// Group of a catalog entry. Open enum.
    public struct Honeypot64CatalogGroup: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Remote access.
        public static let remote: Self = "remote"
        /// Web.
        public static let web: Self = "web"
        /// Mail.
        public static let mail: Self = "mail"
        /// Databases.
        public static let db: Self = "db"
        /// IoT.
        public static let iot: Self = "iot"
        /// Other.
        public static let other: Self = "other"
    }

    /// State of a port in the catalog. Open enum.
    public struct Honeypot64PortState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Free.
        public static let free: Self = "free"
        /// Trap is open.
        public static let open: Self = "open"
        /// Sensor could not open it.
        public static let error: Self = "error"
        /// Another part of the node has it open.
        public static let used: Self = "used"
        /// Another part of the node reserved it.
        public static let reserved: Self = "reserved"
    }

    /// Group of an attack on the live map. Open enum.
    public struct Honeypot64EventGroup: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// Login attempt.
        public static let login: Self = "login"
        /// Exploit.
        public static let exploit: Self = "exploit"
        /// Scan.
        public static let scan: Self = "scan"
        /// Probe.
        public static let probe: Self = "probe"
        /// From logs.
        public static let log: Self = "log"
    }
}
