import Foundation
import Testing
@testable import IPv64

@Suite("Node64 DNS64")
struct Node64DNS64Tests {
    @Test("status decodes blocking state")
    func status() async throws {
        let transport = MockTransport(json: """
        {"version":"1.0","listen":"0.0.0.0:53","startedAt":"2026-10-27T08:00:00Z","router":"192.168.1.1",
         "routerSource":"auto","retentionDays":7,
         "blocking":{"paused":true,"until_resumed":false,"paused_until":"2026-10-27T09:00:00Z"}}
        """)
        let status = try await Node64.mock(transport).dns64.status()
        #expect(status.listen == "0.0.0.0:53")
        #expect(status.retentionDays == 7)
        #expect(status.blocking?.paused == true)
        #expect(status.blocking?.pausedUntil != nil)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/status")
    }

    @Test("summary decodes and sends range")
    func summary() async throws {
        let transport = MockTransport(json: """
        {"summary":{"total":100,"blocked":20,"cached":50,"clients":3,"avgUpstreamMs":12.5,"droppedLogEntries":0},
         "blocklistSize":1000,"listsLoadedAt":"2026-10-27T08:00:00Z",
         "cache":{"entries":5,"max":100,"hits":3,"misses":2},"uptimeSeconds":60,"version":"1.0"}
        """)
        let summary = try await Node64.mock(transport).dns64.summary(range: .last7Days)
        #expect(summary.summary?.total == 100)
        #expect(summary.summary?.avgUpstreamMs == 12.5)
        #expect(summary.cache?.entries == 5)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/summary?range=7d")
    }

    @Test("timeline decodes buckets")
    func timeline() async throws {
        let transport = MockTransport(json: #"{"stepMs":120000,"buckets":[{"t":1793088000000,"total":4,"blocked":1}]}"#)
        let timeline = try await Node64.mock(transport).dns64.timeline()
        #expect(timeline.stepMs == 120_000)
        #expect(timeline.buckets?.first?.date == Date(timeIntervalSince1970: 1_793_088_000))
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/timeline")
    }

    @Test("top builds query and decodes items")
    func top() async throws {
        let transport = MockTransport(json: #"[{"name":"ads.example","count":9,"blocked":9}]"#)
        let items = try await Node64.mock(transport).dns64.top(kind: .blocked, range: .lastHour, limit: 5)
        #expect(items.first?.id == "ads.example")
        let path = try #require(transport.lastRequest?.nodeRelativePath)
        #expect(path.hasPrefix("/dns64/top?"))
        #expect(path.contains("kind=blocked"))
        #expect(path.contains("range=1h"))
        #expect(path.contains("limit=5"))
    }

    @Test("log decodes rows and uses limit and offset")
    func log() async throws {
        let transport = MockTransport(json: """
        {"rows":[{"t":1793088000000,"client":"192.168.1.5","clientName":"laptop","domain":"a.example","qtype":"A",
        "status":"blocked","reason":"group:a.example","rcode":"NXDOMAIN","upstream":"cf","ms":1.5,"proto":"doh","group":"Kids"}],"total":1}
        """)
        let log = try await Node64.mock(transport).dns64.log(status: .blocked, query: "a b", limit: 50, offset: 100, group: "")
        let row = try #require(log.rows?.first)
        #expect(row.status == .blocked)
        #expect(row.proto == .doh)
        #expect(row.ms == 1.5)
        #expect(log.total == 1)
        let path = try #require(transport.lastRequest?.nodeRelativePath)
        #expect(path.contains("status=blocked"))
        #expect(path.contains("offset=100"))
        #expect(path.contains("q=a%20b") || path.contains("q=a+b"))
    }

    @Test("settings decode, including unknown enum values")
    func settingsDecode() async throws {
        let transport = MockTransport(json: """
        {"port":53,"bind":"0.0.0.0","router":"","retention_days":7,"upstream_mode":"fastest",
         "upstreams":[{"name":"CF","url":"https://dns.example/dns-query","ips":["1.1.1.1"],"enabled":true,"custom":false}],
         "lists":[{"name":"L","url":"https://l.example/l.txt","enabled":true,"custom":true}],
         "list_hours":24,"block_mode":"nxdomain","cache_size":1000,"anonymize":"mask","allow_nets":["10.0.0.0/8"],
         "doh":true,"dot":false,"doq":false,"doh_port":443,"dot_port":853,"names":["dns.home"],"cert_mode":"future",
         "notify_upstream":true,"notify_lists":false,"acme_domain":"d","acme_prefix":"p","acme_email":"e","acme_staging":true,
         "upstream_count":2,"cert_id":4,"firefox_canary":true}
        """)
        let settings = try await Node64.mock(transport).dns64.settings()
        #expect(settings.upstreamMode == .fastest)
        #expect(settings.blockMode == .nxdomain)
        #expect(settings.anonymize == .mask)
        #expect(settings.certMode == Node64.DNS64CertMode(rawValue: "future"))
        #expect(settings.upstreams?.first?.ips == ["1.1.1.1"])
        #expect(settings.lists?.first?.custom == true)
        #expect(settings.certID == 4)
        #expect(settings.firefoxCanary == true)
    }

    @Test("updateSettings sends only the given fields")
    func updateSettings() async throws {
        let transport = MockTransport(json: #"{"upstream_mode":"ordered","block_mode":"nxdomain","anonymize":"mask"}"#)
        let result = try await Node64.mock(transport).dns64.updateSettings(
            .init(upstreamMode: .ordered, blockMode: .nxdomain, anonymize: .mask)
        )
        #expect(result.upstreamMode == .ordered)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.nodeRelativePath == "/dns64/settings")
        #expect(request.jsonBody == .object([
            "upstream_mode": .string("ordered"),
            "block_mode": .string("nxdomain"),
            "anonymize": .string("mask"),
        ]))
    }

    @Test("pause sends minutes, resume posts without body")
    func pauseResume() async throws {
        let transport = MockTransport(json: #"{"paused":true,"until_resumed":true}"#)
        let node = Node64.mock(transport)
        let blocking = try await node.dns64.pause(minutes: 0)
        #expect(blocking.untilResumed == true)
        #expect(transport.lastRequest?.jsonBody == .object(["minutes": .number(0)]))
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/pause")

        _ = try await node.dns64.resume()
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/resume")
    }

    @Test("caCertificate and mobileConfig return raw data with the right Accept header")
    func files() async throws {
        let bytes = Data([0x30, 0x82, 0x01])
        let transport = MockTransport(status: 200, body: bytes, headers: ["Content-Type": "application/x-x509-ca-cert"])
        let node = Node64.mock(transport)

        let cert = try await node.dns64.caCertificate()
        #expect(cert == bytes)
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Accept") == "application/x-x509-ca-cert")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/ca.crt")

        let profile = try await node.dns64.mobileConfig(transport: .dot, host: "dns.home")
        #expect(profile == bytes)
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Accept") == "application/x-apple-aspen-config")
        let path = try #require(transport.lastRequest?.nodeRelativePath)
        #expect(path.contains("proto=dot"))
        #expect(path.contains("host=dns.home"))
    }

    @Test("lists: list, add and remove")
    func lists() async throws {
        let transport = MockTransport(json: """
        [{"name":"L","url":"https://l.example/l.txt","rules":42,"updatedAt":"2026-10-27T08:00:00Z","error":"x","failures":1}]
        """)
        let node = Node64.mock(transport)
        let lists = try await node.dns64.lists.list()
        #expect(lists.first?.rules == 42)
        #expect(lists.first?.failures == 1)
        #expect(lists.first?.updatedAt != nil)

        let settingsTransport = MockTransport(status: 201, json: #"{"port":53}"#)
        let settingsNode = Node64.mock(settingsTransport)
        let settings = try await settingsNode.dns64.lists.add("https://l.example/l.txt", name: "L")
        #expect(settings.port == 53)
        #expect(settingsTransport.lastRequest?.jsonBody == .object(["url": .string("https://l.example/l.txt"), "name": .string("L")]))

        _ = try await settingsNode.dns64.lists.remove("https://l.example/a b.txt")
        #expect(settingsTransport.lastRequest?.httpMethod == "DELETE")
        let path = try #require(settingsTransport.lastRequest?.nodeRelativePath)
        #expect(path.hasPrefix("/dns64/lists?url="))
    }

    @Test("upstreams decode statistics and add sends ips")
    func upstreams() async throws {
        let transport = MockTransport(json: """
        {"mode":"parallel","servers":[{"name":"CF","url":"https://dns.example/dns-query","proto":"doh","ips":["1.1.1.1"],
        "requests":10,"wins":6,"errors":1,"avgMs":9.5,"healthy":true,"lastError":"e","lastErrorAt":"2026-10-27T08:00:00Z","active":true}],
        "localDNS":"192.168.1.1","localSource":"auto","count":1}
        """)
        let node = Node64.mock(transport)
        let upstreams = try await node.dns64.upstreams.list()
        #expect(upstreams.mode == .parallel)
        #expect(upstreams.servers?.first?.proto == .doh)
        #expect(upstreams.servers?.first?.avgMs == 9.5)
        #expect(upstreams.localDNS == "192.168.1.1")

        let postTransport = MockTransport(status: 201, json: "{}")
        _ = try await Node64.mock(postTransport).dns64.upstreams.add("tls://dns.example", ips: ["9.9.9.9"])
        #expect(postTransport.lastRequest?.jsonBody == .object([
            "url": .string("tls://dns.example"),
            "ips": .array([.string("9.9.9.9")]),
        ]))
        #expect(postTransport.lastRequest?.nodeRelativePath == "/dns64/upstreams")
    }

    @Test("cache get and flush")
    func cache() async throws {
        let transport = MockTransport(json: #"{"entries":5,"max":100,"staleEntries":1,"hits":3,"misses":2,"staleServed":1,"refreshed":4,"refreshFailures":0}"#)
        let cache = try await Node64.mock(transport).dns64.cache.get()
        #expect(cache.refreshed == 4)

        let flushTransport = MockTransport(json: #"{"flushed":5}"#)
        let result = try await Node64.mock(flushTransport).dns64.cache.flush()
        #expect(result.flushed == 5)
        #expect(flushTransport.lastRequest?.nodeRelativePath == "/dns64/cache/flush")
        #expect(flushTransport.lastRequest?.httpMethod == "POST")
    }

    @Test("allowlist list, add, import, and remove with 204")
    func allowlist() async throws {
        let listTransport = MockTransport(json: #"[{"domain":"example.com","addedAt":"2026-10-27T08:00:00Z"}]"#)
        let entries = try await Node64.mock(listTransport).dns64.allowlist.list()
        #expect(entries.first?.domain == "example.com")
        #expect(entries.first?.addedAt != nil)

        let addTransport = MockTransport(json: #"{"domain":"example.com"}"#)
        let added = try await Node64.mock(addTransport).dns64.allowlist.add("Example.com")
        #expect(added.domain == "example.com")
        #expect(addTransport.lastRequest?.jsonBody == .object(["domain": .string("Example.com")]))

        let importTransport = MockTransport(json: #"{"imported":2,"invalid":1}"#)
        let imported = try await Node64.mock(importTransport).dns64.allowlist.importDomains(["a.example", "b.example", "!!"])
        #expect(imported.imported == 2)
        #expect(imported.invalid == 1)
        #expect(importTransport.lastRequest?.nodeRelativePath == "/dns64/allowlist/import")

        let removeTransport = MockTransport(status: 204, body: Data())
        try await Node64.mock(removeTransport).dns64.allowlist.remove("example.com")
        #expect(removeTransport.lastRequest?.httpMethod == "DELETE")
        #expect(removeTransport.lastRequest?.nodeRelativePath == "/dns64/allowlist?domain=example.com")
    }

    @Test("API errors become Node64Error.api")
    func errorDocument() async throws {
        let transport = MockTransport(
            status: 400,
            json: #"{"error":"Ungueltiger Domainname","field":"domain"}"#,
            headers: ["Content-Type": "application/json"]
        )
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).dns64.allowlist.add("###")
        }
        guard case .api(let document) = error else {
            Issue.record("Expected an API error, got \(String(describing: error))")
            return
        }
        #expect(document.status == 400)
        #expect(document.field == "domain")
    }
}
