import Foundation
import Testing
@testable import IPv64

@Suite("Node64 Honeypot")
struct Node64HoneypotTests {
    @Test("Status decodes")
    func decodeStatus() throws {
        let status = try IPv64Coding.makeDecoder().decode(Node64.Honeypot64Status.self, from: Data("""
        {"version":"1.0","running":true,"started_at":"2026-10-27T08:00:00Z","profile":"standard","scan":true,
         "services":[{"service":"ssh","port":22,"listen":true,"conns":5},{"service":"http","port":80,"listen":false,"error":"in use"}],
         "warnings":[{"service":"http","port":80,"owner":"web","purpose":"Web","skipped":true}],
         "counters":{"connections":10,"logins":4,"events":9,"dropped":0},"buffered":0,"dropped":0,
         "report":{"enabled":true,"key_set":true,"active":true,"last_success":"2026-10-27T08:10:00Z","last_rejected_reasons":{"not_public":3}},
         "logs":{"files":[{"path":"/var/log/auth.log","ok":true,"lines":5}],"syslog":null,"lines":5,"hits":1,"events":1}}
        """.utf8))
        #expect(status.running == true)
        #expect(status.startedAt == Date(timeIntervalSince1970: 1_793_088_000))
        #expect(status.services?.count == 2)
        #expect(status.warnings?.first?.skipped == true)
        #expect(status.counters?.logins == 4)
        #expect(status.report?.keySet == true)
        #expect(status.report?.lastRejectedReasons == ["not_public": 3])
        #expect(status.logs?.syslog == nil)
        #expect(status.logs?.files?.first?.lines == 5)
    }

    @Test("Stats, events, catalog and live decode")
    func decodeOthers() throws {
        let stats = try IPv64Coding.makeDecoder().decode(Node64.Honeypot64Stats.self, from: Data("""
        {"since":"2026-10-26T08:00:00Z","events":10,"sources":3,"logins":2,
         "top_sources":[{"key":"198.51.100.7","count":5,"last":"2026-10-27T08:00:00Z","country":"DE"}],
         "by_country":[{"key":"DE","count":5,"sources":1,"last":"2026-10-27T08:00:00Z"}],
         "timeline":[{"time":"2026-10-27T08:00:00Z","events":4}],"country_unknown":1}
        """.utf8))
        #expect(stats.topSources?.first?.country == "DE")
        #expect(stats.topSources?.first?.id == "198.51.100.7")
        #expect(stats.byCountry?.first?.sources == 1)
        #expect(stats.timeline?.first?.events == 4)

        let event = try IPv64Coding.makeDecoder().decode(Node64.Honeypot64Event.self, from: Data("""
        {"time":"2026-10-27T08:00:00Z","service":"ssh","port":22,"kind":"ssh:bruteforce","src":"198.51.100.7","src_port":4444,
         "username":"root","password":"x","user_agent":"curl","payload_hex":"00","source":"honeypot","fingerprint":"hassh:abc"}
        """.utf8))
        #expect(event.srcPort == 4444)
        #expect(event.source == .honeypot)

        let catalog = try IPv64Coding.makeDecoder().decode(Node64.Honeypot64Catalog.self, from: Data("""
        {"profile":"custom","running":true,
         "entries":[{"service":"ssh","port":2222,"default_port":22,"proto":"tcp","group":"remote","on":true,"state":"open","conns":3}],
         "services":["ssh"],"presets":{"minimal":[{"service":"ssh","port":22}]}}
        """.utf8))
        #expect(catalog.entries?.first?.defaultPort == 22)
        #expect(catalog.entries?.first?.state == .open)
        #expect(catalog.presets?["minimal"]?.first?.port == 22)

        let live = try IPv64Coding.makeDecoder().decode(Node64.Honeypot64Live.self, from: Data("""
        {"minutes":60,"now":1793088000000,"target":{"cc":"DE","x":500.5,"y":100,"known":true,"manual":false},
         "events":[{"t":1793087000000,"cc":"US","x":1,"y":2.5,"ip":"198.51.100.7","group":"login","port":22}]}
        """.utf8))
        #expect(live.target?.x == 500.5)
        #expect(live.events?.first?.group == .login)
    }

    @Test("Events query includes source and country")
    func eventsQuery() async throws {
        let transport = MockTransport(json: "[]")

        let events = try await Node64.mock(transport).honeypot.events(limit: 10, source: .syslog, country: "de")

        #expect(events.isEmpty)
        let path = try #require(transport.lastRequest).nodeRelativePath
        #expect(path.hasPrefix("/honeypot/events?"))
        #expect(path.contains("limit=10") && path.contains("source=syslog") && path.contains("country=de"))
    }

    @Test("Stats and live send their parameters")
    func statsAndLive() async throws {
        let stats = MockTransport(json: "{}")
        _ = try await Node64.mock(stats).honeypot.stats(since: "7d", top: 5)
        let statsPath = try #require(stats.lastRequest).nodeRelativePath
        #expect(statsPath.contains("since=7d") && statsPath.contains("top=5"))

        let live = MockTransport(json: "{}")
        _ = try await Node64.mock(live).honeypot.live(minutes: 30)
        #expect(live.lastRequest?.nodeRelativePath == "/honeypot/live?minutes=30")
    }

    @Test("Clearing events returns the deleted count")
    func clearEvents() async throws {
        let transport = MockTransport(json: #"{"deleted":12}"#)
        let result = try await Node64.mock(transport).honeypot.clearEvents()
        #expect(result.deleted == 12)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
        #expect(transport.lastRequest?.nodeRelativePath == "/honeypot/events")
    }

    @Test("Updating the config encodes snake_case keys and nested objects")
    func updateSettings() async throws {
        let transport = MockTransport(json: #"{"profile":"custom","retention_days":14}"#)
        let config = Node64.Honeypot64Config(
            profile: .custom,
            services: [.init(service: "http", port: 8080, page: .wpLogin)],
            maxConnsPerIP: 8,
            retentionDays: 14,
            log: .init(files: [.init(path: "/var/log/auth.log", format: .auto)], syslogPort: 514),
            login: .init(threshold: 5)
        )

        let result = try await Node64.mock(transport).honeypot.updateSettings(config)

        #expect(result.retentionDays == 14)
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.jsonBody == .object([
            "profile": .string("custom"),
            "services": .array([.object(["service": .string("http"), "port": .number(8080), "page": .string("wp-login")])]),
            "max_conns_per_ip": .number(8),
            "retention_days": .number(14),
            "log": .object([
                "files": .array([.object(["path": .string("/var/log/auth.log"), "format": .string("auto")])]),
                "syslog_port": .number(514),
            ]),
            "login": .object(["threshold": .number(5)]),
        ]))
    }

    @Test("Validation errors keep per-field messages")
    func fieldError() async throws {
        let transport = MockTransport(status: 400, json: #"{"error":"invalid","fields":{"report":"API key missing"}}"#)
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).honeypot.updateSettings(.init(report: true))
        }
        guard case .api(let document) = error else {
            Issue.record("Expected an API error")
            return
        }
        #expect(document.fields == ["report": "API key missing"])
    }
}
