import Foundation

extension Node64 {
    /// Type of an access of a host.
    public struct Monitor64AccessType: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `agent`
        public static let agent: Monitor64AccessType = "agent"
        /// `ssh`
        public static let ssh: Monitor64AccessType = "ssh"
        /// `pve`
        public static let pve: Monitor64AccessType = "pve"
        /// `pbs`
        public static let pbs: Monitor64AccessType = "pbs"
        /// `docker`
        public static let docker: Monitor64AccessType = "docker"
        /// `prom`
        public static let prom: Monitor64AccessType = "prom"
        /// `nut`
        public static let nut: Monitor64AccessType = "nut"
        /// `truenas`
        public static let truenas: Monitor64AccessType = "truenas"
        /// `unraid`
        public static let unraid: Monitor64AccessType = "unraid"
        /// `redfish`
        public static let redfish: Monitor64AccessType = "redfish"
        /// `snmp`
        public static let snmp: Monitor64AccessType = "snmp"
    }

    /// NUT: TLS mode. Empty = STARTTLS if offered.
    public struct Monitor64AccessConfigTls: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// ``
        public static let auto: Monitor64AccessConfigTls = ""
        /// `off`
        public static let off: Monitor64AccessConfigTls = "off"
        /// `require`
        public static let require: Monitor64AccessConfigTls = "require"
    }

    /// TrueNAS: API flavour. Empty = automatic.
    public struct Monitor64AccessConfigApi: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// ``
        public static let auto: Monitor64AccessConfigApi = ""
        /// `jsonrpc`
        public static let jsonrpc: Monitor64AccessConfigApi = "jsonrpc"
        /// `rest`
        public static let rest: Monitor64AccessConfigApi = "rest"
    }

    /// Agent: who connects. Empty = the node queries the agent.
    public struct Monitor64AccessConfigMode: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// ``
        public static let pull: Monitor64AccessConfigMode = ""
        /// `push`
        public static let push: Monitor64AccessConfigMode = "push"
    }

    /// SNMP version (`2` becomes `2c`).
    public struct Monitor64AccessConfigSnmpVersion: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `1`
        public static let v1: Monitor64AccessConfigSnmpVersion = "1"
        /// `2`
        public static let v2: Monitor64AccessConfigSnmpVersion = "2"
        /// `2c`
        public static let v2c: Monitor64AccessConfigSnmpVersion = "2c"
        /// `3`
        public static let v3: Monitor64AccessConfigSnmpVersion = "3"
    }

    /// SNMPv3 security level (default `authPriv`).
    public struct Monitor64AccessConfigLevel: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `noAuthNoPriv`
        public static let noAuthNoPriv: Monitor64AccessConfigLevel = "noAuthNoPriv"
        /// `authNoPriv`
        public static let authNoPriv: Monitor64AccessConfigLevel = "authNoPriv"
        /// `authPriv`
        public static let authPriv: Monitor64AccessConfigLevel = "authPriv"
    }

    /// SNMPv3 authentication protocol.
    public struct Monitor64AccessConfigAuthProto: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `SHA`
        public static let sha: Monitor64AccessConfigAuthProto = "SHA"
        /// `SHA224`
        public static let sha224: Monitor64AccessConfigAuthProto = "SHA224"
        /// `SHA256`
        public static let sha256: Monitor64AccessConfigAuthProto = "SHA256"
        /// `SHA384`
        public static let sha384: Monitor64AccessConfigAuthProto = "SHA384"
        /// `SHA512`
        public static let sha512: Monitor64AccessConfigAuthProto = "SHA512"
        /// `MD5`
        public static let md5: Monitor64AccessConfigAuthProto = "MD5"
    }

    /// SNMPv3 encryption protocol.
    public struct Monitor64AccessConfigPrivProto: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `AES`
        public static let aes: Monitor64AccessConfigPrivProto = "AES"
        /// `AES192`
        public static let aes192: Monitor64AccessConfigPrivProto = "AES192"
        /// `AES256`
        public static let aes256: Monitor64AccessConfigPrivProto = "AES256"
        /// `AES192C`
        public static let aes192c: Monitor64AccessConfigPrivProto = "AES192C"
        /// `AES256C`
        public static let aes256c: Monitor64AccessConfigPrivProto = "AES256C"
        /// `DES`
        public static let des: Monitor64AccessConfigPrivProto = "DES"
    }

    /// Kind of a host (empty = none).
    public struct Monitor64HostKind: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// ``
        public static let unspecified: Monitor64HostKind = ""
        /// `linux-agent`
        public static let linuxAgent: Monitor64HostKind = "linux-agent"
        /// `windows`
        public static let windows: Monitor64HostKind = "windows"
        /// `freebsd`
        public static let freebsd: Monitor64HostKind = "freebsd"
        /// `ssh`
        public static let ssh: Monitor64HostKind = "ssh"
        /// `pve`
        public static let pve: Monitor64HostKind = "pve"
        /// `pbs`
        public static let pbs: Monitor64HostKind = "pbs"
        /// `docker`
        public static let docker: Monitor64HostKind = "docker"
        /// `truenas`
        public static let truenas: Monitor64HostKind = "truenas"
        /// `unraid`
        public static let unraid: Monitor64HostKind = "unraid"
        /// `server`
        public static let server: Monitor64HostKind = "server"
        /// `ups`
        public static let ups: Monitor64HostKind = "ups"
        /// `prom`
        public static let prom: Monitor64HostKind = "prom"
        /// `snmp`
        public static let snmp: Monitor64HostKind = "snmp"
        /// `nas`
        public static let nas: Monitor64HostKind = "nas"
    }

    /// Agent update state: `current` up to date, `pending` update available, `nofile` no file for the platform, `elsewhere` another node is responsible, `off` access switched off.
    public struct Monitor64AgentHostState: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `current`
        public static let current: Monitor64AgentHostState = "current"
        /// `pending`
        public static let pending: Monitor64AgentHostState = "pending"
        /// `unknown`
        public static let unknown: Monitor64AgentHostState = "unknown"
        /// `nofile`
        public static let nofile: Monitor64AgentHostState = "nofile"
        /// `elsewhere`
        public static let elsewhere: Monitor64AgentHostState = "elsewhere"
        /// `off`
        public static let off: Monitor64AgentHostState = "off"
    }

    /// Category of a service on the host page.
    public struct Monitor64HostServiceCategory: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `system`
        public static let system: Monitor64HostServiceCategory = "system"
        /// `fs`
        public static let fs: Monitor64HostServiceCategory = "fs"
        /// `storage`
        public static let storage: Monitor64HostServiceCategory = "storage"
        /// `disks`
        public static let disks: Monitor64HostServiceCategory = "disks"
        /// `network`
        public static let network: Monitor64HostServiceCategory = "network"
        /// `devices`
        public static let devices: Monitor64HostServiceCategory = "devices"
        /// `guests`
        public static let guests: Monitor64HostServiceCategory = "guests"
        /// `docker`
        public static let docker: Monitor64HostServiceCategory = "docker"
        /// `winsvc`
        public static let winsvc: Monitor64HostServiceCategory = "winsvc"
        /// `local`
        public static let local: Monitor64HostServiceCategory = "local"
        /// `access`
        public static let access: Monitor64HostServiceCategory = "access"
        /// `other`
        public static let other: Monitor64HostServiceCategory = "other"
    }

    /// Level a value of an effective threshold comes from.
    public struct Monitor64EffectiveOrigin: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `default`
        public static let standard: Monitor64EffectiveOrigin = "default"
        /// `override`
        public static let deviation: Monitor64EffectiveOrigin = "override"
        /// `host`
        public static let host: Monitor64EffectiveOrigin = "host"
        /// `service`
        public static let service: Monitor64EffectiveOrigin = "service"
    }

    /// Chart of the host page.
    public struct Monitor64HostDetailChartID: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `cpu`
        public static let cpu: Monitor64HostDetailChartID = "cpu"
        /// `ram`
        public static let ram: Monitor64HostDetailChartID = "ram"
        /// `net`
        public static let net: Monitor64HostDetailChartID = "net"
        /// `disk`
        public static let disk: Monitor64HostDetailChartID = "disk"
    }

    /// Target kind of a deviation.
    public struct Monitor64LevelsOverrideTargetType: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `group`
        public static let group: Monitor64LevelsOverrideTargetType = "group"
        /// `tag`
        public static let tag: Monitor64LevelsOverrideTargetType = "tag"
    }

    /// Wanted state of a guest or container (empty = none).
    public struct Monitor64ServiceSoll: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// ``
        public static let unset: Monitor64ServiceSoll = ""
        /// `run`
        public static let run: Monitor64ServiceSoll = "run"
        /// `off`
        public static let off: Monitor64ServiceSoll = "off"
    }

    /// Report mode of a service (empty = notify, `show` = display only).
    public struct Monitor64ServiceReport: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// ``
        public static let unset: Monitor64ServiceReport = ""
        /// `show`
        public static let show: Monitor64ServiceReport = "show"
    }

    /// Scope of a threshold change: only this service or all services of the kind on the host.
    public struct Monitor64ServiceUpdateScope: IPv64OpenEnum {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// `service`
        public static let service: Monitor64ServiceUpdateScope = "service"
        /// `kind`
        public static let kind: Monitor64ServiceUpdateScope = "kind"
    }

    /// New state of services for ``Node64/Monitor64/Hosts/adoptServices(host:keys:state:)``.
    public enum Monitor64AdoptState: Int, Codable, Hashable, Sendable {
        /// Adopt (`1`).
        case adopt = 1
        /// Ignore (`-1`).
        case ignore = -1
        /// Offer as new again (`0`).
        case offerAgain = 0
    }

    /// Configuration of an access without secrets. It is checked strictly (unknown fields and fields of another access type give `400`). SNMP fields only for `snmp`, `metrics` only for `prom`. The same type is used in responses and requests; `nil` fields are not sent.
    public struct Monitor64AccessConfig: Codable, Hashable, Sendable {
        /// Port (0 = default of the access type).
        public var port: Int?

        /// User (SSH and agent `^[A-Za-z0-9._-]{0,32}$`; SNMPv3 at most 32 characters; otherwise up to 128 characters, also user@domain).
        public var user: String?

        /// SSH: SMART via sudo smartctl.
        public var smart: Bool?

        /// Address of the interface (at most 512 characters): http(s)://; Docker also unix://, tcp://, ssh://; TrueNAS and Redfish https:// only; NUT host[:3493] or nut://; Prometheus URL of the exporter; not allowed for SNMP.
        public var url: String?

        /// Token ID (e.g. Proxmox `user@realm!token`).
        public var tokenID: String?

        /// Node name (Proxmox VE).
        public var node: String?

        /// Certificate fingerprint (SHA-256 hex) or SSH host key (`SHA256:...`, Docker ssh://).
        public var pin: String?

        /// NUT: UPS names, comma separated (empty = all).
        public var ups: String?

        /// NUT: TLS mode.
        public var tls: Monitor64AccessConfigTls?

        /// TrueNAS: API flavour.
        public var api: Monitor64AccessConfigApi?

        /// Redfish: session instead of basic auth.
        public var session: Bool?

        /// Agent: pull or push.
        public var mode: Monitor64AccessConfigMode?

        /// Agent in push mode: pointer to the access (at most 64 characters). Gives no access, so it is part of the response, but treat it like a secret.
        public var token: String?

        /// Prometheus only: own metrics (at most 50).
        public var metrics: [Metric]?

        /// SNMP: version.
        public var snmpVersion: Monitor64AccessConfigSnmpVersion?

        /// SNMPv3 level.
        public var level: Monitor64AccessConfigLevel?

        /// SNMPv3 authentication.
        public var authProto: Monitor64AccessConfigAuthProto?

        /// SNMPv3 encryption.
        public var privProto: Monitor64AccessConfigPrivProto?

        /// SNMPv3 context (usually empty).
        public var context: String?

        /// SNMP: own OIDs.
        public var custom: [CustomOID]?

        /// SNMP: fixed profiles (at most 16; empty = automatic).
        public var profiles: [String]?

        /// SNMP: accept traps of this host.
        public var traps: Bool?

        /// SNMPv3: engine ID of the sender for traps (hex).
        public var trapEngineID: String?

        /// A custom Prometheus metric.
        public struct Metric: Codable, Hashable, Sendable {
            /// Metric name, e.g. `nginx_connections_active`.
            public var name: String

            /// Labels that must match exactly (`""` = label missing or empty).
            public var labels: [String: String]?

            /// Display name (empty = name).
            public var title: String?

            /// Unit, e.g. `%`, `B`, `B/s`, `°C`, `ms`.
            public var unit: String?

            /// Value times factor (0 = 1).
            public var factor: Double?

            /// Counter: change per second.
            public var rate: Bool?

            /// Creates the value; pass only what you want to send.
            public init(
                name: String,
                labels: [String: String]? = nil,
                title: String? = nil,
                unit: String? = nil,
                factor: Double? = nil,
                rate: Bool? = nil
            ) {
                self.name = name
                self.labels = labels
                self.title = title
                self.unit = unit
                self.factor = factor
                self.rate = rate
            }

            enum CodingKeys: String, CodingKey {
                case name
                case labels
                case title
                case unit
                case factor
                case rate
            }
        }

        /// A custom SNMP OID.
        public struct CustomOID: Codable, Hashable, Sendable {
            /// OID.
            public var oid: String

            /// Name.
            public var name: String

            /// Unit.
            public var unit: String?

            /// Factor (0 = 1).
            public var factor: Double?

            /// Counter: rate per second times factor.
            public var counter: Bool?

            /// Rule kind for thresholds, e.g. `temp.system`.
            public var rule: String?

            /// Creates the value; pass only what you want to send.
            public init(
                oid: String,
                name: String,
                unit: String? = nil,
                factor: Double? = nil,
                counter: Bool? = nil,
                rule: String? = nil
            ) {
                self.oid = oid
                self.name = name
                self.unit = unit
                self.factor = factor
                self.counter = counter
                self.rule = rule
            }

            enum CodingKeys: String, CodingKey {
                case oid
                case name
                case unit
                case factor
                case counter
                case rule
            }
        }

        /// Creates the value; pass only what you want to send.
        public init(
            port: Int? = nil,
            user: String? = nil,
            smart: Bool? = nil,
            url: String? = nil,
            tokenID: String? = nil,
            node: String? = nil,
            pin: String? = nil,
            ups: String? = nil,
            tls: Monitor64AccessConfigTls? = nil,
            api: Monitor64AccessConfigApi? = nil,
            session: Bool? = nil,
            mode: Monitor64AccessConfigMode? = nil,
            token: String? = nil,
            metrics: [Metric]? = nil,
            snmpVersion: Monitor64AccessConfigSnmpVersion? = nil,
            level: Monitor64AccessConfigLevel? = nil,
            authProto: Monitor64AccessConfigAuthProto? = nil,
            privProto: Monitor64AccessConfigPrivProto? = nil,
            context: String? = nil,
            custom: [CustomOID]? = nil,
            profiles: [String]? = nil,
            traps: Bool? = nil,
            trapEngineID: String? = nil
        ) {
            self.port = port
            self.user = user
            self.smart = smart
            self.url = url
            self.tokenID = tokenID
            self.node = node
            self.pin = pin
            self.ups = ups
            self.tls = tls
            self.api = api
            self.session = session
            self.mode = mode
            self.token = token
            self.metrics = metrics
            self.snmpVersion = snmpVersion
            self.level = level
            self.authProto = authProto
            self.privProto = privProto
            self.context = context
            self.custom = custom
            self.profiles = profiles
            self.traps = traps
            self.trapEngineID = trapEngineID
        }

        enum CodingKeys: String, CodingKey {
            case port
            case user
            case smart
            case url
            case tokenID = "token_id"
            case node
            case pin
            case ups
            case tls
            case api
            case session
            case mode
            case token
            case metrics
            case snmpVersion = "snmp_version"
            case level
            case authProto = "auth_proto"
            case privProto = "priv_proto"
            case context
            case custom
            case profiles
            case traps
            case trapEngineID = "trap_engine_id"
        }
    }

    /// Access of a host without its secret.
    public struct Monitor64Access: Codable, Hashable, Sendable {
        /// UID of the access.
        public let uid: String

        /// Access type.
        public let type: Monitor64AccessType?

        /// Configuration.
        public let config: Monitor64AccessConfig?

        /// Remembered SSH host key (fingerprint).
        public let hostkey: String?

        /// Access is switched on.
        public let enabled: Bool?

        /// A secret is stored (the secret itself is never returned).
        public let secretSet: Bool?

        enum CodingKeys: String, CodingKey {
            case uid
            case type
            case config
            case hostkey
            case enabled
            case secretSet = "secret_set"
        }
    }

    /// Create or change an access. `secret` and `clearSecret` are write-only secrets: they are never returned (only `secretSet` on the response) and should not be logged.
    public struct Monitor64AccessInput: Codable, Hashable, Sendable {
        /// Access type; required when creating, empty on PUT = unchanged.
        public var type: Monitor64AccessType?

        /// Configuration. On PUT `nil` keeps the existing one (it is checked again).
        public var config: Monitor64AccessConfig?

        /// SECRET, write-only. Token or password; Docker: TLS key, certificate and CA as PEM or the private SSH key; SNMP: JSON `{"community", "auth", "priv"}` or just the community (empty fields keep the stored value). At most 4096 bytes, Docker 64 KiB. `nil`/empty = unchanged.
        public var secret: String?

        /// Remove the stored secret (write-only).
        public var clearSecret: Bool?

        /// Agent in push mode: generate a new token.
        public var newToken: Bool?

        /// Confirmed SSH host key fingerprint (`SHA256:...`, taken while none is remembered); on PUT `reset` discards the remembered key.
        public var hostkey: String?

        /// Switch the access on or off; `nil` = unchanged (new: on).
        public var enabled: Bool?

        /// Creates the value; pass only what you want to send.
        public init(
            type: Monitor64AccessType? = nil,
            config: Monitor64AccessConfig? = nil,
            secret: String? = nil,
            clearSecret: Bool? = nil,
            newToken: Bool? = nil,
            hostkey: String? = nil,
            enabled: Bool? = nil
        ) {
            self.type = type
            self.config = config
            self.secret = secret
            self.clearSecret = clearSecret
            self.newToken = newToken
            self.hostkey = hostkey
            self.enabled = enabled
        }

        enum CodingKeys: String, CodingKey {
            case type
            case config
            case secret
            case clearSecret = "clear_secret"
            case newToken = "new_token"
            case hostkey
            case enabled
        }
    }

    /// Agent state of a host.
    public struct Monitor64AgentHost: Codable, Hashable, Sendable {
        /// Host UID.
        public let uid: String?

        /// Name of the host.
        public let name: String?

        /// UID of the agent access.
        public let access: String?

        /// Push mode.
        public let push: Bool?

        /// Agent version.
        public let version: String?

        /// Platform, e.g. `linux-amd64`.
        public let platform: String?

        /// Automatic updates.
        public let auto: Bool?

        /// Update state.
        public let state: Monitor64AgentHostState?

        /// An update runs or waits for a free slot.
        public let busy: Bool?

        /// Error of the last attempt.
        public let error: String?

        /// Last attempt.
        public let tried: Date?

        /// Next automatic attempt.
        public let next: Date?

        /// For `elsewhere`: responsible node.
        public let node: String?

        /// Available version.
        public let latest: String?

        /// Access is switched off.
        public let disabled: Bool?

        enum CodingKeys: String, CodingKey {
            case uid
            case name
            case access
            case push
            case version
            case platform
            case auto
            case state
            case busy
            case error
            case tried
            case next
            case node
            case latest
            case disabled
        }
    }

    /// Agent file for one platform.
    public struct Monitor64AgentFile: Codable, Hashable, Sendable {
        /// File name.
        public let name: String?

        /// Operating system.
        public let os: String?

        /// Architecture.
        public let arch: String?

        /// Size in bytes.
        public let size: Int?

        /// SHA-256.
        public let sha256: String?

        /// Platform key, e.g. `linux-amd64`.
        public let key: String?

        /// Verified copy lies on the node.
        public let cached: Bool?

        enum CodingKeys: String, CodingKey {
            case name
            case os
            case arch
            case size
            case sha256
            case key
            case cached
        }
    }

    /// State of the agent distribution.
    public struct Monitor64Agent: Codable, Hashable, Sendable {
        /// Folder of the agent files on the internet.
        public let internet: String?

        /// HTTP port of the node (0 = off).
        public let httpPort: Int?

        /// Agent port.
        public let port: Int?

        /// Module runs.
        public let running: Bool?

        /// Current version.
        public let version: String?

        /// Date of the version.
        public let date: String?

        /// Source of the signed directory.
        public let source: Source?

        /// Directory should be fetched again.
        public let due: Bool?

        /// Files.
        public let files: [Monitor64AgentFile]?

        /// Install scripts.
        public let scripts: [Script]?

        /// Hosts with their agent state.
        public let hosts: [Monitor64AgentHost]?

        /// Recent agent events.
        public let events: [Event]?

        /// Public key.
        public let publicKey: String?

        /// Fingerprint.
        public let fingerprint: String?

        /// Source of the signed directory.
        public struct Source: Codable, Hashable, Sendable {
            /// Base URLs.
            public let bases: [String]?

            /// Source in use.
            public let source: String?

            /// Last check.
            public let checked: Date?

            /// Last success.
            public let ok: Date?

            /// Last error.
            public let error: String?

            enum CodingKeys: String, CodingKey {
                case bases
                case source
                case checked
                case ok
                case error
            }
        }

        /// Install script.
        public struct Script: Codable, Hashable, Sendable {
            /// Name.
            public let name: String?

            /// Size in bytes.
            public let size: Int?

            /// SHA-256.
            public let sha256: String?

            enum CodingKeys: String, CodingKey {
                case name
                case size
                case sha256
            }
        }

        /// Entry of the agent timeline: an event plus the host.
        public struct Event: Codable, Hashable, Sendable {
            /// Time.
            public let at: Date?

            /// Kind.
            public let kind: String?

            /// Text.
            public let text: String?

            /// Actor.
            public let actor: Monitor64Actor?

            /// Host UID.
            public let hostUID: String?

            /// Service key.
            public let key: String?

            /// Problem UID.
            public let problem: String?

            /// Name of the host.
            public let host: String?

            enum CodingKeys: String, CodingKey {
                case at
                case kind
                case text
                case actor
                case hostUID = "host_uid"
                case key
                case problem
                case host
            }
        }

        enum CodingKeys: String, CodingKey {
            case internet
            case httpPort = "http_port"
            case port
            case running
            case version
            case date
            case source
            case due
            case files
            case scripts
            case hosts
            case events
            case publicKey = "public_key"
            case fingerprint
        }
    }

    /// Discovered service (result of a connection test). Also used when creating a host.
    public struct Monitor64DiscoveredService: Codable, Hashable, Sendable {
        /// Key of the service (at most 200 characters).
        public var key: String

        /// Display name (at most 200 characters).
        public var name: String?

        /// Kind, e.g. `cpu`, `mem`, `fs`, `disk`, `if`, `vm`, `ctr` (at most 32 characters).
        public var kind: String?

        /// Offered by default.
        public var isDefault: Bool?

        /// Creates the value; pass only what you want to send.
        public init(
            key: String,
            name: String? = nil,
            kind: String? = nil,
            isDefault: Bool? = nil
        ) {
            self.key = key
            self.name = name
            self.kind = kind
            self.isDefault = isDefault
        }

        enum CodingKeys: String, CodingKey {
            case key
            case name
            case kind
            case isDefault = "default"
        }
    }

    /// Effective threshold after resolving all levels.
    public struct Monitor64Effective: Codable, Hashable, Sendable {
        /// Rule kind.
        public let kind: String?

        /// Kind is in the default table.
        public let known: Bool?

        /// State rule (severity instead of numbers).
        public let isState: Bool?

        /// Warning.
        public let warn: Monitor64Limit?

        /// Critical.
        public let crit: Monitor64Limit?

        /// Warning GB free.
        public let warnFree: Monitor64Limit?

        /// Critical GB free.
        public let critFree: Monitor64Limit?

        /// Direction.
        public let dir: Monitor64RuleDir?

        /// Seconds.
        public let forSeconds: Int?

        /// Hysteresis.
        public let hyst: Double?

        /// Mode.
        public let mode: Monitor64RuleMode?

        /// Report.
        public let report: Monitor64RuleReport?

        /// Severity.
        public let severity: Monitor64RuleSeverity?

        /// Field to level the value comes from.
        public let origin: [String: Monitor64EffectiveOrigin]?

        /// Index of the effective deviation, -1 = none.
        public let override: Int?

        /// UID of the effective deviation.
        public let overrideID: String?

        enum CodingKeys: String, CodingKey {
            case kind
            case known
            case isState = "is_state"
            case warn
            case crit
            case warnFree = "warn_free"
            case critFree = "crit_free"
            case dir
            case forSeconds = "for"
            case hyst
            case mode
            case report
            case severity
            case origin
            case override
            case overrideID = "override_id"
        }
    }

    /// A host.
    public struct Monitor64Host: Codable, Hashable, Sendable {
        /// UID of the host.
        public let uid: String

        /// Name.
        public let name: String?

        /// Hostname, IPv4 or IPv6 (without brackets).
        public let address: String?

        /// Kind of the host.
        public let kind: Monitor64HostKind?

        /// Group.
        public let group: String?

        /// Tags (lower case).
        public let tags: [String]?

        /// Query interval in seconds (30 to 900).
        public let intervalSec: Int?

        /// Cluster: responsible node.
        public let ownerNode: String?

        /// Cluster: preferred node.
        public let preferredNode: String?

        /// Cluster: substitute nodes.
        public let backupNodes: [String]?

        /// Update the agent automatically.
        public let agentAutoupdate: Bool?

        /// Queries are paused.
        public let paused: Bool?

        /// Notes.
        public let notes: String?

        /// Created.
        public let createdAt: Date?

        /// Last changed.
        public let updatedAt: Date?

        enum CodingKeys: String, CodingKey {
            case uid
            case name
            case address
            case kind
            case group
            case tags
            case intervalSec = "interval_sec"
            case ownerNode = "owner_node"
            case preferredNode = "preferred_node"
            case backupNodes = "backup_nodes"
            case agentAutoupdate = "agent_autoupdate"
            case paused
            case notes
            case createdAt = "created_at"
            case updatedAt = "updated_at"
        }
    }

    /// Fields of a host. `PUT` replaces all fields; only `kind`, `intervalSec` and `agentAutoupdate` stay when empty, 0 or `nil`.
    public struct Monitor64HostInput: Codable, Hashable, Sendable {
        /// Required; at most 100 characters (control characters removed).
        public var name: String

        /// Required; hostname, IPv4 or IPv6 (square brackets are removed).
        public var address: String

        /// Kind; empty = none (create) or unchanged (update).
        public var kind: Monitor64HostKind?

        /// Group (at most 64 characters; empty = none).
        public var group: String?

        /// Tags, lower-cased; duplicates and empty ones are dropped (at most 32).
        public var tags: [String]?

        /// Interval in seconds; 0 = default from the settings (create) or unchanged (update); clamped to 30 to 900.
        public var intervalSec: Int?

        /// Notes (at most 1000 characters).
        public var notes: String?

        /// Pause queries.
        public var paused: Bool?

        /// Update the agent automatically; `nil` = unchanged (new: on).
        public var agentAutoupdate: Bool?

        /// Creates the value; pass only what you want to send.
        public init(
            name: String,
            address: String,
            kind: Monitor64HostKind? = nil,
            group: String? = nil,
            tags: [String]? = nil,
            intervalSec: Int? = nil,
            notes: String? = nil,
            paused: Bool? = nil,
            agentAutoupdate: Bool? = nil
        ) {
            self.name = name
            self.address = address
            self.kind = kind
            self.group = group
            self.tags = tags
            self.intervalSec = intervalSec
            self.notes = notes
            self.paused = paused
            self.agentAutoupdate = agentAutoupdate
        }

        enum CodingKeys: String, CodingKey {
            case name
            case address
            case kind
            case group
            case tags
            case intervalSec = "interval_sec"
            case notes
            case paused
            case agentAutoupdate = "agent_autoupdate"
        }
    }

    /// Creates a host with accesses (all fields on one level): the fields of ``Monitor64HostInput`` plus accesses and discovered services.
    public struct Monitor64HostCreate: Codable, Hashable, Sendable {
        /// Required; at most 100 characters (control characters removed).
        public var name: String

        /// Required; hostname, IPv4 or IPv6 (square brackets are removed).
        public var address: String

        /// Kind; empty = none (create) or unchanged (update).
        public var kind: Monitor64HostKind?

        /// Group (at most 64 characters; empty = none).
        public var group: String?

        /// Tags, lower-cased; duplicates and empty ones are dropped (at most 32).
        public var tags: [String]?

        /// Interval in seconds; 0 = default from the settings (create) or unchanged (update); clamped to 30 to 900.
        public var intervalSec: Int?

        /// Notes (at most 1000 characters).
        public var notes: String?

        /// Pause queries.
        public var paused: Bool?

        /// Update the agent automatically; `nil` = unchanged (new: on).
        public var agentAutoupdate: Bool?

        /// Accesses (at most 8).
        public var accesses: [Monitor64AccessInput]?

        /// Discovered services from the connection test (entered as new; at most 5000).
        public var services: [Monitor64DiscoveredService]?

        /// Keys of services to adopt immediately.
        public var adopt: [String]?

        /// Creates the value; pass only what you want to send.
        public init(
            name: String,
            address: String,
            kind: Monitor64HostKind? = nil,
            group: String? = nil,
            tags: [String]? = nil,
            intervalSec: Int? = nil,
            notes: String? = nil,
            paused: Bool? = nil,
            agentAutoupdate: Bool? = nil,
            accesses: [Monitor64AccessInput]? = nil,
            services: [Monitor64DiscoveredService]? = nil,
            adopt: [String]? = nil
        ) {
            self.name = name
            self.address = address
            self.kind = kind
            self.group = group
            self.tags = tags
            self.intervalSec = intervalSec
            self.notes = notes
            self.paused = paused
            self.agentAutoupdate = agentAutoupdate
            self.accesses = accesses
            self.services = services
            self.adopt = adopt
        }

        enum CodingKeys: String, CodingKey {
            case name
            case address
            case kind
            case group
            case tags
            case intervalSec = "interval_sec"
            case notes
            case paused
            case agentAutoupdate = "agent_autoupdate"
            case accesses
            case services
            case adopt
        }
    }

    /// Evaluation of a metric.
    public struct Monitor64MetricStatus: Codable, Hashable, Sendable {
        /// State.
        public let state: Monitor64State?

        /// Result of the thresholds without unknown.
        public let level: Monitor64State?

        /// Since.
        public let since: Date?

        /// Last measurement.
        public let at: Date?

        /// Evaluated value (mode free: GB free).
        public let value: Double?

        /// Threshold.
        public let threshold: Monitor64Limit?

        /// Pending state (duration running).
        public let pending: Monitor64State?

        /// Pending since.
        public let pendingSince: Date?

        /// Pending last measurement.
        public let pendingAt: Date?

        /// Pending threshold.
        public let pendingLimit: Monitor64Limit?

        enum CodingKeys: String, CodingKey {
            case state
            case level
            case since
            case at
            case value
            case threshold
            case pending
            case pendingSince = "pending_since"
            case pendingAt = "pending_at"
            case pendingLimit = "pending_limit"
        }
    }

    /// A measured value of a service.
    public struct Monitor64Metric: Codable, Hashable, Sendable {
        /// Name, e.g. `util`, `used`, `in`, `out`, `temp`.
        public let name: String?

        /// Value.
        public let value: Double?

        /// Unit.
        public let unit: String?

        /// Rule kind (empty = display only).
        public let rule: String?

        /// Maximum, e.g. size in bytes.
        public let max: Double?

        /// Evaluation.
        public let status: Monitor64MetricStatus?

        /// Rule kind.
        public let ruleKind: String?

        enum CodingKeys: String, CodingKey {
            case name
            case value
            case unit
            case rule
            case max
            case status
            case ruleKind = "rule_kind"
        }
    }

    /// A service.
    public struct Monitor64Service: Codable, Hashable, Sendable {
        /// Key.
        public let key: String?

        /// Name.
        public let name: String?

        /// Kind.
        public let kind: String?

        /// State.
        public let state: Monitor64State?

        /// Text.
        public let text: String?

        /// Cause.
        public let cause: String?

        /// Access it comes from.
        public let via: String?

        /// `1` adopted, `0` new, `-1` ignored.
        public let adopted: Int?

        /// Vanished.
        public let vanished: Bool?

        /// Display only.
        public let showOnly: Bool?

        /// Acknowledged.
        public let acked: Bool?

        /// Measured values.
        public let metrics: [Monitor64Metric]?

        enum CodingKeys: String, CodingKey {
            case key
            case name
            case kind
            case state
            case text
            case cause
            case via
            case adopted
            case vanished
            case showOnly = "show_only"
            case acked
            case metrics
        }
    }

    /// Levels of a threshold on a service.
    public struct Monitor64Levels: Codable, Hashable, Sendable {
        /// Rule kind.
        public let kind: String?

        /// Metric (empty = state rule).
        public let metric: String?

        /// State rule.
        public let state: Bool?

        /// Default.
        public let std: Monitor64Rule?

        /// Effective deviation.
        public let override: Override?

        /// This host, all services of the kind.
        public let hostKind: Monitor64Rule?

        /// Only this service.
        public let service: Monitor64Rule?

        /// Effective threshold.
        public let eff: Monitor64Effective?

        /// Effective deviation.
        public struct Override: Codable, Hashable, Sendable {
            /// Index.
            public let index: Int?

            /// UID.
            public let uid: String?

            /// Group or tag.
            public let targetType: Monitor64LevelsOverrideTargetType?

            /// Target.
            public let target: String?

            /// Rule.
            public let rule: Monitor64Rule?

            enum CodingKeys: String, CodingKey {
                case index
                case uid
                case targetType = "target_type"
                case target
                case rule
            }
        }

        enum CodingKeys: String, CodingKey {
            case kind
            case metric
            case state
            case std
            case override
            case hostKind = "host_kind"
            case service
            case eff
        }
    }

    /// Service on the host page: all fields of ``Monitor64Service`` plus category, problem and thresholds.
    public struct Monitor64HostService: Codable, Hashable, Sendable {
        /// Key.
        public let key: String?

        /// Name.
        public let name: String?

        /// Kind.
        public let kind: String?

        /// State.
        public let state: Monitor64State?

        /// Text.
        public let text: String?

        /// Cause.
        public let cause: String?

        /// Access it comes from.
        public let via: String?

        /// `1` adopted, `0` new, `-1` ignored.
        public let adopted: Int?

        /// Vanished.
        public let vanished: Bool?

        /// Display only.
        public let showOnly: Bool?

        /// Acknowledged.
        public let acked: Bool?

        /// Measured values.
        public let metrics: [Monitor64Metric]?

        /// Category.
        public let category: Monitor64HostServiceCategory?

        /// Problem open since.
        public let since: Date?

        /// Acknowledgement.
        public let ack: Monitor64Ack?

        /// Own display name.
        public let customName: String?

        /// Wanted state.
        public let soll: String?

        /// Report mode.
        public let report: String?

        /// Guest or container with wanted state.
        public let guest: Bool?

        /// Index of the first metric with a threshold (-1 = none).
        public let primary: Int?

        /// Levels.
        public let levels: Monitor64Levels?

        /// All rule kinds of the service.
        public let rules: [Monitor64Levels]?

        enum CodingKeys: String, CodingKey {
            case key
            case name
            case kind
            case state
            case text
            case cause
            case via
            case adopted
            case vanished
            case showOnly = "show_only"
            case acked
            case metrics
            case category
            case since
            case ack
            case customName = "custom_name"
            case soll
            case report
            case guest
            case primary
            case levels
            case rules
        }
    }

    /// Stored service.
    public struct Monitor64ServiceRow: Codable, Hashable, Sendable {
        /// UID.
        public let uid: String?

        /// Host UID.
        public let hostUID: String?

        /// Key.
        public let key: String?

        /// Own display name.
        public let name: String?

        /// Kind.
        public let kind: String?

        /// `1` adopted, `0` new, `-1` ignored.
        public let adopted: Int?

        /// Vanished at.
        public let vanishedAt: Date?

        /// Access.
        public let via: String?

        /// Thresholds "only this service" (JSON).
        public let hostRule: String?

        /// Wanted state.
        public let soll: Monitor64ServiceSoll?

        /// Report mode.
        public let report: Monitor64ServiceReport?

        enum CodingKeys: String, CodingKey {
            case uid
            case hostUID = "host_uid"
            case key
            case name
            case kind
            case adopted
            case vanishedAt = "vanished_at"
            case via
            case hostRule = "host_rule"
            case soll
            case report
        }
    }

    /// Effective maintenance window.
    public struct Monitor64Window: Codable, Hashable, Sendable {
        /// ID.
        public let id: String?

        /// Hosts.
        public let hosts: [String]?

        /// Groups.
        public let groups: [String]?

        /// Tags.
        public let tags: [String]?

        /// Start.
        public let start: Date?

        /// End.
        public let end: Date?

        /// Recurrence.
        public let recurring: Monitor64Recurrence?

        /// Reason.
        public let reason: String?

        enum CodingKeys: String, CodingKey {
            case id
            case hosts
            case groups
            case tags
            case start
            case end
            case recurring
            case reason
        }
    }

    /// Access on the host page with runtime state: all fields of ``Monitor64Access`` plus state.
    public struct Monitor64AccessState: Codable, Hashable, Sendable {
        /// UID of the access.
        public let uid: String

        /// Access type.
        public let type: Monitor64AccessType?

        /// Configuration.
        public let config: Monitor64AccessConfig?

        /// Remembered SSH host key.
        public let hostkey: String?

        /// Switched on.
        public let enabled: Bool?

        /// A secret is stored (never returned).
        public let secretSet: Bool?

        /// Display name of the access type.
        public let name: String?

        /// Last query succeeded.
        public let ok: Bool?

        /// Failures in a row.
        public let failures: Int?

        /// Error.
        public let error: String?

        /// Already queried.
        public let known: Bool?

        /// Agent state (agent accesses only).
        public let agent: Monitor64AgentHost?

        enum CodingKeys: String, CodingKey {
            case uid
            case type
            case config
            case hostkey
            case enabled
            case secretSet = "secret_set"
            case name
            case ok
            case failures
            case error
            case known
            case agent
        }
    }

    /// Host with services, accesses (without secrets), new and ignored services.
    public struct Monitor64HostDetail: Codable, Hashable, Sendable {
        /// Host.
        public let host: Monitor64Host?

        /// Icon.
        public let icon: String?

        /// State.
        public let state: Monitor64State?

        /// View.
        public let view: Monitor64View?

        /// Last round.
        public let checked: Date?

        /// Effective maintenance.
        public let maint: Monitor64Window?

        /// Error when unreachable.
        public let unreach: String?

        /// Services.
        public let services: [Monitor64HostService]?

        /// Accesses.
        public let accesses: [Monitor64AccessState]?

        /// Newly detected, not yet adopted services.
        public let new: [Monitor64ServiceRow]?

        /// Ignored services.
        public let ignored: [Monitor64ServiceRow]?

        /// Charts of the host page.
        public let charts: [Chart]?

        /// Module runs.
        public let running: Bool?

        /// Chart of the host page.
        public struct Chart: Codable, Hashable, Sendable {
            /// Chart.
            public let id: Monitor64HostDetailChartID?

            /// Unit.
            public let unit: String?

            /// Maximum.
            public let max: Double?

            /// Series.
            public let series: [Series]?

            /// Warning line.
            public let warn: Double?

            /// Critical line.
            public let crit: Double?

            /// Series of a chart.
            public struct Series: Codable, Hashable, Sendable {
                /// Label.
                public let label: String?

                /// Service key.
                public let svc: String?

                /// Metric.
                public let metric: String?

                enum CodingKeys: String, CodingKey {
                    case label
                    case svc
                    case metric
                }
            }

            enum CodingKeys: String, CodingKey {
                case id
                case unit
                case max
                case series
                case warn
                case crit
            }
        }

        enum CodingKeys: String, CodingKey {
            case host
            case icon
            case state
            case view
            case checked
            case maint
            case unreach
            case services
            case accesses
            case new
            case ignored
            case charts
            case running
        }
    }

    /// Trap state of a host (in a cluster the state of the responsible node).
    public struct Monitor64HostTraps: Codable, Hashable, Sendable {
        /// Traps, newest first.
        public let list: [Trap]?

        /// Open traps.
        public let pending: Int?

        /// Total.
        public let total: Int?

        /// Rejected.
        public let rejected: Int?

        /// Reason for rejection.
        public let rejectReason: String?

        /// Last rejection.
        public let rejectedAt: Date?

        /// Variable binding of a trap.
        public struct Varbind: Codable, Hashable, Sendable {
            /// OID.
            public let oid: String?

            /// Type.
            public let type: String?

            /// Value.
            public let value: String?

            enum CodingKeys: String, CodingKey {
                case oid
                case type
                case value
            }
        }

        /// A received trap.
        public struct Trap: Codable, Hashable, Sendable {
            /// Time.
            public let time: Date?

            /// SNMP version.
            public let version: String?

            /// Inform request.
            public let inform: Bool?

            /// SNMPv3 user.
            public let user: String?

            /// Trap OID.
            public let trapOID: String?

            /// Trap name.
            public let trapName: String?

            /// Kind.
            public let kind: String?

            /// Known trap: immediate query only.
            public let handled: Bool?

            /// Variable bindings.
            public let varbinds: [Varbind]?

            /// Truncated.
            public let truncated: Bool?

            enum CodingKeys: String, CodingKey {
                case time
                case version
                case inform
                case user
                case trapOID = "trap_oid"
                case trapName = "trap_name"
                case kind
                case handled
                case varbinds
                case truncated
            }
        }

        enum CodingKeys: String, CodingKey {
            case list
            case pending
            case total
            case rejected
            case rejectReason = "reject_reason"
            case rejectedAt = "rejected_at"
        }
    }

    /// Change of a service; missing fields stay unchanged.
    public struct Monitor64ServiceUpdate: Codable, Hashable, Sendable {
        /// Key of the service.
        public var key: String

        /// Display name (empty = detected name; at most 200 characters).
        public var name: String?

        /// Wanted state of guests and containers.
        public var soll: Monitor64ServiceSoll?

        /// `show` = display only.
        public var report: Monitor64ServiceReport?

        /// Rule kind to change of the level "this host" (at most 32 kinds); missing kinds stay.
        public var rules: [String: RuleChange]?

        /// Remove all thresholds of this host for the kinds of this service.
        public var reset: Bool?

        /// Change of one rule kind on the host level. Pass an empty ``Monitor64Rule`` to remove the rule, or `reset` to remove both settings of the kind.
        public struct RuleChange: Codable, Hashable, Sendable {
            /// New rule; an empty rule removes it. Leaving it out (`nil`) is sent as missing, which the node most likely treats as null and so also removes the rule.
            public var rule: Monitor64Rule?

            /// `service` (default) or `kind`.
            public var scope: Monitor64ServiceUpdateScope?

            /// Remove both settings on the host for this kind.
            public var reset: Bool?

            /// Creates the value; pass only what you want to send.
            public init(
                rule: Monitor64Rule? = nil,
                scope: Monitor64ServiceUpdateScope? = nil,
                reset: Bool? = nil
            ) {
                self.rule = rule
                self.scope = scope
                self.reset = reset
            }

            enum CodingKeys: String, CodingKey {
                case rule
                case scope
                case reset
            }
        }

        /// Creates the value; pass only what you want to send.
        public init(
            key: String,
            name: String? = nil,
            soll: Monitor64ServiceSoll? = nil,
            report: Monitor64ServiceReport? = nil,
            rules: [String: RuleChange]? = nil,
            reset: Bool? = nil
        ) {
            self.key = key
            self.name = name
            self.soll = soll
            self.report = report
            self.rules = rules
            self.reset = reset
        }

        enum CodingKeys: String, CodingKey {
            case key
            case name
            case soll
            case report
            case rules
            case reset
        }
    }

    /// Input of a connection test (nothing is saved).
    public struct Monitor64TestInput: Codable, Hashable, Sendable {
        /// Address of the host.
        public var address: String

        /// Access to test.
        public var access: Monitor64AccessInput?

        /// Stored access: must belong to the host with this address; empty fields in `access` (also the secret) count as stored, the type must not change.
        public var accessUID: String?

        /// Creates the value; pass only what you want to send.
        public init(
            address: String,
            access: Monitor64AccessInput? = nil,
            accessUID: String? = nil
        ) {
            self.address = address
            self.access = access
            self.accessUID = accessUID
        }

        enum CodingKeys: String, CodingKey {
            case address
            case access
            case accessUID = "access_uid"
        }
    }

    /// Result of a connection test. A failed test is `200` with `ok == false`.
    public struct Monitor64TestResult: Codable, Hashable, Sendable {
        /// Success.
        public let ok: Bool?

        /// Error text (also partial errors).
        public let error: String?

        /// Duration in milliseconds.
        public let ms: Int?

        /// Fingerprint of certificate or SSH host key.
        public let fingerprint: String?

        /// Discovered services.
        public let services: [Monitor64DiscoveredService]?

        /// Confirm the fingerprint first (store as `pin`/`hostkey`), then test again.
        public let needConfirm: Bool?

        /// Certificate from a known CA or pin matches.
        public let trusted: Bool?

        /// Certificate subject.
        public let certSubject: String?

        /// Version.
        public let version: String?

        /// Node.
        public let node: String?

        /// Cluster.
        public let cluster: String?

        /// Proxmox: nodes of the cluster.
        public let nodes: [Node]?

        /// Summary.
        public let summary: String?

        /// Warning.
        public let warning: String?

        /// SNMP: nas, ups, printer, switch, router, ap, server, device.
        public let device: String?

        /// SNMP: detected profiles.
        public let profiles: [Profile]?

        /// SNMP: what is queried.
        public let queries: [String]?

        /// A node of the Proxmox cluster.
        public struct Node: Codable, Hashable, Sendable {
            /// Name.
            public let name: String?

            /// IP.
            public let ip: String?

            /// ID.
            public let id: Int?

            /// Online.
            public let online: Bool?

            /// Node behind the queried address.
            public let local: Bool?

            enum CodingKeys: String, CodingKey {
                case name
                case ip
                case id
                case online
                case local
            }
        }

        /// A detected SNMP profile.
        public struct Profile: Codable, Hashable, Sendable {
            /// ID.
            public let id: String?

            /// Name.
            public let name: String?

            /// Verified on a real device.
            public let verified: Bool?

            enum CodingKeys: String, CodingKey {
                case id
                case name
                case verified
            }
        }

        enum CodingKeys: String, CodingKey {
            case ok
            case error
            case ms
            case fingerprint
            case services
            case needConfirm = "need_confirm"
            case trusted
            case certSubject = "cert_subject"
            case version
            case node
            case cluster
            case nodes
            case summary
            case warning
            case device
            case profiles
            case queries
        }
    }

    /// Answer of creating or changing a host.
    public struct Monitor64HostUID: Codable, Hashable, Sendable {
        /// UID of the host.
        public let uid: String

        enum CodingKeys: String, CodingKey {
            case uid
        }
    }

    /// Answer of deleting a host.
    public struct Monitor64HostDeleted: Codable, Hashable, Sendable {
        /// `true`.
        public let ok: Bool?

        /// Deleted series.
        public let seriesDeleted: Int?

        enum CodingKeys: String, CodingKey {
            case ok
            case seriesDeleted = "series_deleted"
        }
    }

    /// Result of a discovery round.
    public struct Monitor64DiscoverResult: Codable, Hashable, Sendable {
        /// Newly entered services.
        public let added: Int?

        /// New services not adopted yet (total).
        public let new: Int?

        /// Vanished services.
        public let vanished: Int?

        enum CodingKeys: String, CodingKey {
            case added
            case new
            case vanished
        }
    }

    /// Number of changed services.
    public struct Monitor64ServicesChanged: Codable, Hashable, Sendable {
        /// Changed services.
        public let changed: Int?

        enum CodingKeys: String, CodingKey {
            case changed
        }
    }

    /// New push token and the push port of the node.
    public struct Monitor64PushToken: Codable, Hashable, Sendable {
        /// Token for the install command (stored only with the access; gives no access).
        public let token: String?

        /// Push port of the node.
        public let port: Int?

        enum CodingKeys: String, CodingKey {
            case token
            case port
        }
    }

    /// Automatic agent updates of a host.
    public struct Monitor64AgentAutoupdate: Codable, Hashable, Sendable {
        /// Host UID.
        public let uid: String?

        /// Automatic updates on.
        public let autoupdate: Bool?

        enum CodingKeys: String, CodingKey {
            case uid
            case autoupdate
        }
    }

    /// Answer of starting an agent update (`202`).
    public struct Monitor64AgentUpdateStarted: Codable, Hashable, Sendable {
        /// `true`.
        public let ok: Bool?

        /// Target version.
        public let version: String?

        enum CodingKeys: String, CodingKey {
            case ok
            case version
        }
    }
}
