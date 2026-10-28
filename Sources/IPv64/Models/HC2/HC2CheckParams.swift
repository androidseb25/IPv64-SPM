import Foundation

/// Type-dependent parameters of a check (keys as in the node). Only the keys relevant for the check type are set.
public struct HC2CheckParams: Codable, Hashable, Sendable {
    /// A condition on the JSON response of a `json` check.
    public struct JSONRule: Codable, Hashable, Sendable {
        /// Path, e.g. `data.items[0].status`.
        public var path: String
        /// Comparison operator.
        public var op: HC2JSONRuleOperator
        /// Value to compare against.
        public var value: String?

        /// Creates a rule.
        public init(path: String, op: HC2JSONRuleOperator, value: String? = nil) {
            self.path = path
            self.op = op
            self.value = value
        }
    }

    /// `http`/`keyword`: method (GET, HEAD, POST, ...).
    public var method: String?

    /// `http`/`keyword`: accepted status codes, e.g. `200-299,301`.
    public var acceptStatus: String?

    /// `http`/`keyword`: follow redirects.
    public var followRedirects: Bool?

    /// `http`/`keyword`: maximum number of redirects.
    public var maxRedirects: Int?

    /// `keyword`: text to search for.
    public var keyword: String?

    /// `keyword`: the text must NOT appear.
    public var keywordAbsent: Bool?

    /// `http`/`keyword`: basic-auth user.
    public var basicUser: String?

    /// `http`/`keyword`: basic-auth password.
    public var basicPassword: String?

    /// `http`/`keyword`: additional request headers.
    public var headers: [String: String]?

    /// `http`/`keyword`: request body.
    public var body: String?

    /// `http`/`keyword`: ignore certificate errors.
    public var insecureTLS: Bool?

    /// `http`/`keyword` (HTTPS): fails if the certificate expires in fewer days (0 = off).
    public var certMinDays: Int?

    /// `icmp`: number of packets (1-20).
    public var count: Int?

    /// `icmp`: maximum packet loss in percent.
    public var maxLossPercent: Int?

    /// `icmp`: maximum latency in milliseconds, 0 = off.
    public var maxLatencyMS: Int?

    /// `tcp`/`port`/`cert`: port, alternatively `host:port` in the target.
    public var port: Int?

    /// `tcp`: data to send.
    public var send: String?

    /// `tcp`: expected response prefix; `port`: `open`|`closed`; `dns`: `any`, `contains`, `equals`, `regex`, `nxdomain`, `public_ip` (local only).
    public var expect: String?

    /// `tcp`: use TLS after connecting.
    public var tls: Bool?

    /// `cert`: minimum remaining validity in days.
    public var minDays: Int?

    /// `cert`: SNI server name.
    public var serverName: String?

    /// `cert`: skip chain validation.
    public var skipChain: Bool?

    /// `cert`: skip hostname validation.
    public var skipHostname: Bool?

    /// `push`: expected interval in seconds.
    public var periodSeconds: Int?

    /// `push`: grace period in seconds.
    public var graceSeconds: Int?

    /// `json`: conditions on the JSON response (at most 10).
    public var jsonRules: [JSONRule]?

    /// `json`: one satisfied condition is enough (otherwise all).
    public var jsonAny: Bool?

    /// `dns`: record type (default A).
    public var recordType: HC2DNSRecordType?

    /// `dns`: resolver to use.
    public var resolver: HC2DNSResolver?

    /// `dns` with `resolver=server`: IP, optionally with port (`1.1.1.1`, `[2606:4700::1111]:53`).
    public var server: String?

    /// `dns`: expected values (contains/equals) or a pattern (regex).
    public var values: [String]?

    /// `dns`: the answer must be DNSSEC-validated.
    public var dnssec: Bool?

    /// `dns`: minimum TTL in seconds (0 = any).
    public var minTTL: Int?

    /// Creates parameters; only non-`nil` fields are sent.
    public init(
        method: String? = nil,
        acceptStatus: String? = nil,
        followRedirects: Bool? = nil,
        maxRedirects: Int? = nil,
        keyword: String? = nil,
        keywordAbsent: Bool? = nil,
        basicUser: String? = nil,
        basicPassword: String? = nil,
        headers: [String: String]? = nil,
        body: String? = nil,
        insecureTLS: Bool? = nil,
        certMinDays: Int? = nil,
        count: Int? = nil,
        maxLossPercent: Int? = nil,
        maxLatencyMS: Int? = nil,
        port: Int? = nil,
        send: String? = nil,
        expect: String? = nil,
        tls: Bool? = nil,
        minDays: Int? = nil,
        serverName: String? = nil,
        skipChain: Bool? = nil,
        skipHostname: Bool? = nil,
        periodSeconds: Int? = nil,
        graceSeconds: Int? = nil,
        jsonRules: [JSONRule]? = nil,
        jsonAny: Bool? = nil,
        recordType: HC2DNSRecordType? = nil,
        resolver: HC2DNSResolver? = nil,
        server: String? = nil,
        values: [String]? = nil,
        dnssec: Bool? = nil,
        minTTL: Int? = nil
    ) {
        self.method = method
        self.acceptStatus = acceptStatus
        self.followRedirects = followRedirects
        self.maxRedirects = maxRedirects
        self.keyword = keyword
        self.keywordAbsent = keywordAbsent
        self.basicUser = basicUser
        self.basicPassword = basicPassword
        self.headers = headers
        self.body = body
        self.insecureTLS = insecureTLS
        self.certMinDays = certMinDays
        self.count = count
        self.maxLossPercent = maxLossPercent
        self.maxLatencyMS = maxLatencyMS
        self.port = port
        self.send = send
        self.expect = expect
        self.tls = tls
        self.minDays = minDays
        self.serverName = serverName
        self.skipChain = skipChain
        self.skipHostname = skipHostname
        self.periodSeconds = periodSeconds
        self.graceSeconds = graceSeconds
        self.jsonRules = jsonRules
        self.jsonAny = jsonAny
        self.recordType = recordType
        self.resolver = resolver
        self.server = server
        self.values = values
        self.dnssec = dnssec
        self.minTTL = minTTL
    }

    enum CodingKeys: String, CodingKey {
        case method
        case acceptStatus = "accept_status"
        case followRedirects = "follow_redirects"
        case maxRedirects = "max_redirects"
        case keyword
        case keywordAbsent = "keyword_absent"
        case basicUser = "basic_user"
        case basicPassword = "basic_password"
        case headers
        case body
        case insecureTLS = "insecure_tls"
        case certMinDays = "cert_min_days"
        case count
        case maxLossPercent = "max_loss_percent"
        case maxLatencyMS = "max_latency_ms"
        case port
        case send
        case expect
        case tls
        case minDays = "min_days"
        case serverName = "server_name"
        case skipChain = "skip_chain"
        case skipHostname = "skip_hostname"
        case periodSeconds = "period_seconds"
        case graceSeconds = "grace_seconds"
        case jsonRules = "json_rules"
        case jsonAny = "json_any"
        case recordType = "record_type"
        case resolver
        case server
        case values
        case dnssec
        case minTTL = "min_ttl"
    }
}
