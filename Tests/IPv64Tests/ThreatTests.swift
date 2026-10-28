import Foundation
import Testing
@testable import IPv64

@Suite("Threat")
struct ThreatTests {
    static let ipJSON = """
    {"data":{"ip":"203.0.113.7","family":4,"listed":true,"status":"listed","score":72,"lists":["ssh"],
    "kinds":["ssh:bruteforce","generic:portscan"],"ports":[{"service":"ssh","port":22}],
    "first_seen":"2026-10-18","last_seen":"2026-10-20","accounts":4,"country":null,"asn":null,
    "release":{"status":"none","protected_until":null},"details":"https://ipv64.net/honeypot/ip.php?ip=203.0.113.7"}}
    """

    static func anonymous(_ transport: MockTransport) -> IPv64 {
        IPv64(configuration: .init(apiKey: nil), transport: transport)
    }

    @Test("GET /threat/ip decodes and sends the key when configured")
    func ipWithKey() async throws {
        let transport = MockTransport(json: Self.ipJSON)
        let ip = try await IPv64.mock(transport).threat.ip("203.0.113.7")

        #expect(ip.listed == true)
        #expect(ip.status == .listed)
        #expect(ip.score == 72)
        #expect(ip.lists == [.ssh])
        #expect(ip.ports?.first?.port == 22)
        #expect(ip.release?.status == ThreatIP.Release.Status.none)
        #expect(ip.release?.protectedUntil == nil)
        #expect(ip.asn == nil)
        let request = try #require(transport.lastRequest)
        #expect(request.relativePath == "/threat/ip/203.0.113.7")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
    }

    @Test("GET /threat/ip works without an API key")
    func ipAnonymous() async throws {
        let transport = MockTransport(json: Self.ipJSON)
        let ip = try await Self.anonymous(transport).threat.ip("203.0.113.7")

        #expect(ip.ip == "203.0.113.7")
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("GET /threat/ip percent-encodes IPv6 addresses")
    func ipv6() async throws {
        let transport = MockTransport(json: #"{"data":{"ip":"2001:db8::1","family":6}}"#)
        let ip = try await IPv64.mock(transport).threat.ip("2001:db8::1")

        #expect(ip.family == 6)
        let path = try #require(transport.lastRequest?.relativePath)
        #expect(path.hasPrefix("/threat/ip/2001"))
        #expect(!path.dropFirst("/threat/ip/".count).contains("/"))
        #expect(transport.lastRequest?.url?.absoluteString.hasSuffix("2001:db8::1") == true)
    }

    @Test("GET /threat/stats decodes the overview")
    func stats() async throws {
        let transport = MockTransport(json: """
        {"data":{"generated_at":"2026-10-20T12:00:00Z","window_days":30,"threshold":{"accounts":2,"active_accounts_7d":12},
        "sensors":{"active_7d":25,"online":21},"attacks_24h":{"events":120345,"sources":4312},
        "timeline":[{"day":"2026-10-19","events":100}],"top_ports":[{"service":"ssh","port":22,"events":5}],
        "top_kinds":[{"kind":"ssh:bruteforce","events":9}],"lists":{"v64":812,"v64_ssh":640},
        "top":{"usernames":[{"value":"admin","events":18423,"accounts":5}],"passwords":[],"paths":[],"user_agents":[],
        "fingerprints":[],"countries":[{"country":"CN","ips":214,"events":51234}]},
        "info":"https://ipv64.net/honeypot/stats.php","license":"CC BY 4.0"}}
        """)
        let stats = try await Self.anonymous(transport).threat.stats()

        #expect(stats.windowDays == 30)
        #expect(stats.threshold?.activeAccounts7d == 12)
        #expect(stats.attacks24h?.events == 120_345)
        #expect(stats.lists?["v64_ssh"] == 640)
        #expect(stats.top?.usernames?.first?.value == "admin")
        #expect(stats.top?.countries?.first?.ips == 214)
        #expect(transport.lastRequest?.relativePath == "/threat/stats")
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("GET /threat/passwords/range returns text and parses entries")
    func passwordRange() async throws {
        let body = "1E4C9B93F3F0682250B6CF8331B7EE68FD8:4211\r\n2F1A0C4B7E9D3A5C6B8E0F1D2C3B4A5968F:0\r\n"
        let transport = MockTransport(status: 200, body: Data(body.utf8), headers: ["Content-Type": "text/plain"])
        let client = Self.anonymous(transport)

        let text = try await client.threat.passwordRange(prefix: "5BAA6")
        #expect(text == body)
        let request = try #require(transport.lastRequest)
        #expect(request.relativePath == "/threat/passwords/range/5BAA6")
        #expect(request.value(forHTTPHeaderField: "Accept")?.hasPrefix("text/plain") == true)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)

        let entries = try await client.threat.passwordRangeEntries(prefix: "5BAA6")
        #expect(entries.count == 2)
        #expect(entries[0] == ThreatPasswordRangeEntry(suffix: "1E4C9B93F3F0682250B6CF8331B7EE68FD8", count: 4211))
        #expect(entries[1].count == 0)
    }

    @Test("Watch networks: list, add and delete")
    func watch() async throws {
        let list = MockTransport(json: """
        {"data":{"limits":{"max":3,"min_prefix_v4":16,"min_prefix_v6":32},
        "networks":[{"id":1,"cidr":"203.0.113.0/24","label":"Büro","verified":false,"created_at":"2026-10-20T12:00:00Z"}],
        "dyndns":[{"ip":"198.51.100.7","domain":"x.ipv64.net"}]}}
        """)
        let watch = try await IPv64.mock(list).threat.watch.list()
        #expect(watch.limits?.minPrefixV4 == 16)
        #expect(watch.networks?.first?.id == 1)
        #expect(watch.dyndns?.first?.domain == "x.ipv64.net")
        #expect(list.lastRequest?.relativePath == "/threat/watch")

        let add = MockTransport(status: 201, json: """
        {"data":{"id":2,"cidr":"203.0.113.0/24","label":"Büro","verified":false,"created_at":"2026-10-20T12:00:00Z"}}
        """)
        let network = try await IPv64.mock(add).threat.watch.add(cidr: "203.0.113.7/24", label: "Büro")
        #expect(network.id == 2)
        let request = try #require(add.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.jsonBody == .object(["cidr": .string("203.0.113.7/24"), "label": .string("Büro")]))

        let noLabel = MockTransport(status: 201, json: #"{"data":{"id":3}}"#)
        _ = try await IPv64.mock(noLabel).threat.watch.add(cidr: "203.0.113.0/24")
        #expect(noLabel.lastRequest?.jsonBody == .object(["cidr": .string("203.0.113.0/24")]))

        let delete = MockTransport(status: 204, body: Data())
        try await IPv64.mock(delete).threat.watch.delete(12)
        #expect(delete.lastRequest?.httpMethod == "DELETE")
        #expect(delete.lastRequest?.relativePath == "/threat/watch/12")
    }

    @Test("GET /threat/watch/alerts decodes alerts and sends since")
    func alerts() async throws {
        let transport = MockTransport(json: """
        {"data":{"alerts":[{"id":7,"ip":"203.0.113.9","cidr":"203.0.113.0/24","network_id":null,"source":"dyndns",
        "label":"x.ipv64.net","listed":true,"score":72,"kinds":["ssh:bruteforce"],"first_seen":"2026-10-19",
        "last_seen":"2026-10-20","created_at":"2026-10-20T12:12:03Z"}],"next":"2026-10-20T12:12:03Z_42"}}
        """)
        let alerts = try await IPv64.mock(transport).threat.watch.alerts(since: "2026-10-20T12:12:03Z_42")

        let alert = try #require(alerts.alerts?.first)
        #expect(alert.id == 7)
        #expect(alert.networkID == nil)
        #expect(alert.source == .dyndns)
        #expect(alerts.next == "2026-10-20T12:12:03Z_42")
        let url = try #require(transport.lastRequest?.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        #expect(items?.first { $0.name == "since" }?.value == "2026-10-20T12:12:03Z_42")
    }

    @Test("GET /threat/feed decodes changes")
    func feed() async throws {
        let transport = MockTransport(json: """
        {"data":{"changes":[{"ip":"203.0.113.7","action":"add","lists":["v64","ssh"],"previous_lists":[],
        "at":"2026-10-20T12:07:00Z"}],"next":"AAAAAGkGJcwAAAAAAAAAKg","more":false}}
        """)
        let feed = try await IPv64.mock(transport).threat.feed()

        #expect(feed.changes?.first?.action == .add)
        #expect(feed.changes?.first?.lists == ["v64", "ssh"])
        #expect(feed.next == "AAAAAGkGJcwAAAAAAAAAKg")
        #expect(feed.more == false)
        #expect(transport.lastRequest?.relativePath == "/threat/feed")
    }

    @Test("GET /threat/feed reports an expired cursor (410)")
    func feedExpired() async throws {
        let transport = MockTransport(status: 410, json: """
        {"type":"about:blank","title":"Gone","status":410,"detail":"Cursor expired","code":"cursor_expired"}
        """)
        do {
            _ = try await IPv64.mock(transport).threat.feed(since: "old")
            Issue.record("Expected an error")
        } catch let error as IPv64Error {
            #expect(error.code == "cursor_expired")
            #expect(error.statusCode == 410)
        }
        #expect(transport.lastRequest?.relativePath == "/threat/feed?since=old")
    }
}
