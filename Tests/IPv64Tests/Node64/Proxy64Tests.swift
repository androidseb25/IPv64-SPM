import Foundation
import Testing
@testable import IPv64

@Suite("Node64 PROXY64")
struct Node64Proxy64Tests {
    @Test("status and stats are returned as free-form JSON")
    func statusAndStats() async throws {
        let transport = MockTransport(json: #"{"hosts":3}"#)
        let proxy = Node64.mock(transport).proxy64

        let status = try await proxy.status()
        #expect(status == .object(["hosts": .number(3)]))
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/status")

        _ = try await proxy.stats(hours: 48, host: 2)
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/stats?hours=48&host=2")
    }

    @Test("check starts a run")
    func check() async throws {
        let transport = MockTransport(status: 202, json: #"{"checking":true}"#)
        let result = try await Node64.mock(transport).proxy64.check()
        #expect(result.checking == true)
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/check")
    }

    @Test("Default page decodes and encodes the default_* keys")
    func defaultPage() async throws {
        let transport = MockTransport(json: #"{"default":"redirect","default_url":"https://example.com","default_html":""}"#)
        let proxy = Node64.mock(transport).proxy64

        let page = try await proxy.defaultPage()
        #expect(page.mode == .redirect)
        #expect(page.url == "https://example.com")

        _ = try await proxy.updateDefaultPage(mode: .html, html: "<p>hi</p>")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.nodeRelativePath == "/cdn64/default")
        #expect(request.jsonBody == .object(["default": .string("html"), "default_html": .string("<p>hi</p>")]))
    }

    @Test("Log entries decode and the query is built")
    func log() async throws {
        let transport = MockTransport(json: """
        [{"id":9,"time":"2026-10-27T10:00:00Z","host_id":2,"client":"203.0.113.5","method":"GET",
          "host":"a.example.com","path":"/x","status":429,"bytes":10,"ms":3,"user_agent":"curl","reason":"req_rate"}]
        """)
        let entries = try await Node64.mock(transport).proxy64.log(host: 2, status: "r", query: "a b", before: 10, limit: 50, rejectedOnly: true)

        #expect(entries.first?.reason == "req_rate")
        #expect(entries.first?.userAgent == "curl")
        #expect(entries.first?.id == 9)
        let path = try #require(transport.lastRequest?.nodeRelativePath)
        #expect(path.hasPrefix("/cdn64/log?"))
        for part in ["host=2", "status=r", "q=a%20b", "before=10", "limit=50", "rejected=1"] {
            #expect(path.contains(part))
        }
    }

    @Test("Settings round trip")
    func settings() async throws {
        let transport = MockTransport(json: #"{"log_days":14,"anonymize":true}"#)
        let proxy = Node64.mock(transport).proxy64

        let settings = try await proxy.settings()
        #expect(settings.logDays == 14)
        #expect(settings.anonymize == true)

        _ = try await proxy.updateSettings(logDays: 30)
        #expect(transport.lastRequest?.jsonBody == .object(["log_days": .number(30)]))
    }

    @Test("A CDNOnlineError body surfaces as Node64Error.code")
    func onlineError() async throws {
        let transport = MockTransport(
            status: 409,
            json: #"{"error":"no api key","code":"no_api_key","text":"Kein ipv64-Account verbunden."}"#,
            headers: ["Content-Type": "application/json"]
        )

        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).proxy64.online.registerTunnel()
        }
        #expect(error?.code == "no_api_key")
        #expect(error?.statusCode == 409)
        #expect(error?.errorDescription == "Kein ipv64-Account verbunden.")
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/online/tunnel")
    }

    @Test("Online status decodes")
    func onlineStatus() async throws {
        let transport = MockTransport(json: """
        {"configured":true,"tunnel":"tn_abc","api_ready":true,
         "edges":[{"name":"srv07","host":"srv07.ipv64.net","connected":true,"transport":"quic","total":4}],
         "names":[{"name":"a.example.com","host_id":2,"remote_id":7,"mode":1,"check":"tok","created_at":"2026-10-27T10:00:00Z"}],
         "quota":{"domains":{"used":1,"old_cdn":0,"limit":5},"traffic_mb":{"used":1.5,"old_cdn":0,"limit":1000},"bandwidth_mbit":0},
         "synced":"2026-10-27T10:00:00Z","udp_buffer":212992,"udp_buffer_low":true}
        """)
        let status = try await Node64.mock(transport).proxy64.online.status()

        #expect(status.tunnel == "tn_abc")
        #expect(status.edges?.first?.transport == .quic)
        #expect(status.names?.first?.remoteID == 7)
        #expect(status.quota?.trafficMB?.used == 1.5)
        #expect(status.udpBufferLow == true)
    }

    @Test("Online enable, disable and test")
    func onlineHostOps() async throws {
        let enableTransport = MockTransport(json: """
        {"results":[{"name":"a.example.com","result":"on"},{"name":"*.example.com","result":"skipped","code":"wildcard_name"}],"check":"tok"}
        """)
        let enabled = try await Node64.mock(enableTransport).proxy64.online.enable(host: 2, mode: 1, healthcheck: true)
        #expect(enabled.results?.map(\.result) == [.on, .skipped])
        #expect(enabled.check == "tok")
        #expect(enableTransport.lastRequest?.nodeRelativePath == "/cdn64/hosts/2/online")
        #expect(enableTransport.lastRequest?.jsonBody == .object(["mode": .number(1), "healthcheck": .bool(true)]))

        let disableTransport = MockTransport(status: 204, body: Data())
        try await Node64.mock(disableTransport).proxy64.online.disable(host: 2)
        #expect(disableTransport.lastRequest?.httpMethod == "DELETE")

        let testTransport = MockTransport(json: """
        [{"name":"a.example.com","tls":true,"dns":["1.2.3.4"],"dns_ok":true,
          "probes":[{"edge":"srv07","addr":"1.2.3.4","family":"ipv4","ok":true,"ms":12,"trusted":true}]}]
        """)
        let tests = try await Node64.mock(testTransport).proxy64.online.test(host: 2)
        #expect(tests.first?.probes?.first?.family == .ipv4)
        #expect(tests.first?.dnsOK == true)
        #expect(testTransport.lastRequest?.nodeRelativePath == "/cdn64/hosts/2/online/test")
    }

    @Test("setTunnel sends the manual tunnel")
    func setTunnel() async throws {
        let transport = MockTransport(json: #"{"configured":true}"#)
        let input = Node64.CDNOnlineTunnelInput(tunnel: "tn_x", edges: [.init(name: "e", host: "h", port: 443, ips: ["1.1.1.1"])])
        _ = try await Node64.mock(transport).proxy64.online.setTunnel(input)

        #expect(transport.lastRequest?.httpMethod == "PUT")
        let edge = JSONValue.object(["name": .string("e"), "host": .string("h"), "port": .number(443), "ips": .array([.string("1.1.1.1")])])
        #expect(transport.lastRequest?.jsonBody == .object(["tunnel": .string("tn_x"), "edges": .array([edge])]))
    }

    @Test("forgetTunnel returns without content")
    func forgetTunnel() async throws {
        let transport = MockTransport(status: 204, body: Data())
        try await Node64.mock(transport).proxy64.online.forgetTunnel()
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/online")
    }

    @Test("Access lists decode and encode")
    func accessLists() async throws {
        let listTransport = MockTransport(json: """
        [{"access_list":{"id":1,"name":"Office","satisfy_any":true,"pass_auth":false,
          "users":[{"username":"anna"}],"rules":[{"action":"allow","cidr":"10.0.0.0/8"}],
          "created_at":"2026-10-27T10:00:00Z","updated_at":"2026-10-27T10:00:00Z"},"used_by":["a.example.com"]}]
        """)
        let entries = try await Node64.mock(listTransport).proxy64.accessLists.list()
        #expect(entries.first?.accessList?.id == 1)
        #expect(entries.first?.accessList?.rules?.first?.action == .allow)
        #expect(entries.first?.usedBy == ["a.example.com"])

        let transport = MockTransport(status: 201, json: #"{"id":2,"name":"New"}"#)
        let input = Node64.CDNAccessListInput(name: "New", satisfyAny: false, users: [.init(username: "bob", password: "pw")], rules: [.init(action: .deny, cidr: "all")])
        let created = try await Node64.mock(transport).proxy64.accessLists.create(input)
        #expect(created.id == 2)
        let user = JSONValue.object(["username": .string("bob"), "password": .string("pw")])
        let rule = JSONValue.object(["action": .string("deny"), "cidr": .string("all")])
        #expect(transport.lastRequest?.jsonBody == .object([
            "name": .string("New"), "satisfy_any": .bool(false), "users": .array([user]), "rules": .array([rule]),
        ]))
    }

    @Test("Access list deletion in use is a 409 error")
    func accessListInUse() async throws {
        let transport = MockTransport(status: 409, json: #"{"error":"list in use"}"#, headers: ["Content-Type": "application/json"])
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).proxy64.accessLists.delete(1)
        }
        guard case .api(let document) = error else {
            Issue.record("Expected an API error")
            return
        }
        #expect(document.status == 409)
        #expect(document.error == "list in use")
    }

    @Test("Blocklists decode and update sends only given fields")
    func blocklists() async throws {
        let transport = MockTransport(json: """
        {"lists":[{"id":"v64","name":"v64","category":"honeypot","enabled":true,"entries":10,
          "updated":"2026-10-27T10:00:00Z","edition":"daily","live_denied":true,"live_error":"live: HTTP 403"}],
         "allow":["192.0.2.1"],"blocked":5,"active":true,
         "countries":[{"code":"DE","entries":100}],"geo_blocked":2,"token_set":true,
         "ai_bots":{"needed":true,"entries":50,"users":3,"blocked":1}}
        """)
        let proxy = Node64.mock(transport).proxy64
        let lists = try await proxy.blocklists.update(enabled: ["v64"], token: "")

        #expect(lists.lists?.first?.edition == .daily)
        #expect(lists.lists?.first?.liveDenied == true)
        #expect(lists.countries?.first?.code == "DE")
        #expect(lists.tokenSet == true)
        #expect(lists.aiBots?.needed == true)
        #expect(transport.lastRequest?.jsonBody == .object(["enabled": .array([.string("v64")]), "token": .string("")]))

        _ = try await proxy.blocklists.refresh()
        #expect(transport.lastRequest?.nodeRelativePath == "/cdn64/blocklists/refresh")
        #expect(transport.lastRequest?.httpMethod == "POST")
    }

    @Test("Honeypot view decodes and blocks are removed by IP")
    func honeypot() async throws {
        let transport = MockTransport(json: """
        {"settings":{"decoy":true,"access":false,"block":true,"block_hours":24},"decoy_available":true,
         "access_available":false,"blocks":[{"ip":"2001:db8::1","reason":"ssh","since":"2026-10-27T10:00:00Z","until":"2026-10-28T10:00:00Z"}],
         "rejected":1,"decoyed":2,"reported":3}
        """)
        let proxy = Node64.mock(transport).proxy64
        let view = try await proxy.honeypot.update(.init(block: true, blockHours: 24))
        #expect(view.settings?.blockHours == 24)
        #expect(view.blocks?.first?.ip == "2001:db8::1")
        #expect(view.decoyAvailable == true)
        #expect(transport.lastRequest?.jsonBody == .object(["block": .bool(true), "block_hours": .number(24)]))

        let deleteTransport = MockTransport(status: 204, body: Data())
        try await Node64.mock(deleteTransport).proxy64.honeypot.unblock("2001:db8::1")
        #expect(deleteTransport.lastRequest?.nodeRelativePath == "/cdn64/honeypot/blocks/2001:db8::1")
    }

    @Test("Limits decode and bans are removed by IP")
    func limits() async throws {
        let transport = MockTransport(json: """
        {"limits":{"enabled":true,"conns_per_ip":100,"exempt_lan":true},"defaults":{"conns_per_ip":200,"ban_minutes":10},
         "bans":[{"ip":"203.0.113.0","until":"2026-10-27T10:10:00Z"}],"rejected":4,"conns":7}
        """)
        let proxy = Node64.mock(transport).proxy64
        let view = try await proxy.limits.update(.init(enabled: true, connsPerIP: 100))
        #expect(view.limits?.connsPerIP == 100)
        #expect(view.defaults?.banMinutes == 10)
        #expect(view.bans?.first?.ip == "203.0.113.0")
        #expect(view.conns == 7)
        #expect(transport.lastRequest?.jsonBody == .object(["enabled": .bool(true), "conns_per_ip": .number(100)]))

        let deleteTransport = MockTransport(status: 204, body: Data())
        try await Node64.mock(deleteTransport).proxy64.limits.unban("203.0.113.0")
        #expect(deleteTransport.lastRequest?.nodeRelativePath == "/cdn64/limits/bans/203.0.113.0")
        #expect(deleteTransport.lastRequest?.httpMethod == "DELETE")
    }
}
