import Foundation
import Testing
@testable import IPv64

@Suite("Node64 node, sonar, link, cluster, dyndns additions")
struct Node64AreaNewTests {
    private func last(_ t: MockTransport) -> (String, String, JSONValue?) {
        (t.lastRequest?.httpMethod ?? "", t.lastRequest?.nodeRelativePath ?? "", t.lastRequest?.jsonBody)
    }

    @Test("users")
    func users() async throws {
        let t = MockTransport(json: #"[{"id":1,"uid":"u1","username":"admin","lang":"de","timezone":"Europe/Berlin","totp":true,"self":true,"created_at":"2026-10-27T10:00:00Z","last_login_at":"2026-10-28T10:00:00Z"}]"#)
        let users = try await Node64.mock(t).node.users.list()
        #expect(users.first?.isSelf == true)
        #expect(users.first?.lang == .de)
        #expect(users.first?.lastLoginAt != nil)
        #expect(last(t).0 == "GET" && last(t).1 == "/users")

        let d = MockTransport(status: 204, body: Data())
        try await Node64.mock(d).node.users.delete(7)
        #expect(last(d).0 == "DELETE" && last(d).1 == "/users/7")

        let m = MockTransport(json: #"{"id":1,"username":"admin","lang":"en","timezone":"UTC"}"#)
        let me = try await Node64.mock(m).node.users.updateMe(language: .en, timezone: "UTC")
        #expect(me.timezone == "UTC")
        #expect(last(m).0 == "PUT" && last(m).1 == "/users/me")
        #expect(last(m).2 == .object(["lang": .string("en"), "timezone": .string("UTC")]))

        let g = MockTransport(json: #"{"id":1,"username":"admin"}"#)
        _ = try await Node64.mock(g).node.users.me()
        #expect(last(g).1 == "/users/me")
    }

    @Test("mcp")
    func mcp() async throws {
        let json = #"{"enabled":true,"path":"/mcp","rate_per_minute":60,"areas":[{"name":"healthchecks","available":true}],"keys":[{"id":3,"name":"k","hint":"ab12","areas":["healthchecks"],"created_at":"2026-10-27T10:00:00Z","last_used_at":"2026-10-28T10:00:00Z","last_ip":"203.0.113.1"}]}"#
        let t = MockTransport(json: json)
        let mcp = try await Node64.mock(t).node.mcp.get()
        #expect(mcp.ratePerMinute == 60)
        #expect(mcp.keys?.first?.lastIP == "203.0.113.1")
        #expect(last(t).1 == "/mcp")

        let p = MockTransport(json: json)
        _ = try await Node64.mock(p).node.mcp.setEnabled(false)
        #expect(last(p).0 == "PUT" && last(p).2 == .object(["enabled": .bool(false)]))

        let c = MockTransport(status: 201, json: #"{"id":4,"name":"n","hint":"zz","areas":["a"],"key":"mcp64_secret"}"#)
        let key = try await Node64.mock(c).node.mcp.createKey(name: "n", areas: ["a"])
        #expect(key.key == "mcp64_secret")
        #expect(last(c).0 == "POST" && last(c).1 == "/mcp/keys")
        #expect(last(c).2 == .object(["name": .string("n"), "areas": .array([.string("a")])]))

        let d = MockTransport(status: 204, body: Data())
        try await Node64.mock(d).node.mcp.deleteKey(4)
        #expect(last(d).0 == "DELETE" && last(d).1 == "/mcp/keys/4")
    }

    @Test("self-update")
    func update() async throws {
        let g = MockTransport(json: #"{"version":"1.2.3"}"#)
        let v = try await Node64.mock(g).node.update.get()
        #expect(v["version"]?.stringValue == "1.2.3")
        #expect(last(g).1 == "/update")

        let c = MockTransport(json: #"{}"#)
        _ = try await Node64.mock(c).node.update.check()
        #expect(last(c).0 == "POST" && last(c).1 == "/update/check")

        let a = MockTransport(status: 202, json: #"{"status":"restarting","version":"1.3.0"}"#)
        let applied = try await Node64.mock(a).node.update.apply()
        #expect(applied.version == "1.3.0")
        #expect(last(a).1 == "/update/apply")

        let r = MockTransport(status: 202, json: #"{"status":"restarting"}"#)
        #expect(try await Node64.mock(r).node.update.reset().status == "restarting")
        #expect(last(r).1 == "/update/reset")

        let s = MockTransport(json: #"{}"#)
        _ = try await Node64.mock(s).node.update.updateSettings(mode: .auto, channel: .stable, window: "03:00-05:00")
        #expect(last(s).0 == "PUT" && last(s).1 == "/update/settings")
        #expect(last(s).2 == .object(["mode": .string("auto"), "channel": .string("stable"), "window": .string("03:00-05:00")]))
    }

    @Test("logging api_log")
    func apiLog() async throws {
        let t = MockTransport(json: #"{"level":"info","modules":{},"api_log":"keys"}"#)
        let s = try await Node64.mock(t).node.updateLogging(apiLog: .keys)
        #expect(s.apiLog == .keys)
        #expect(last(t).2 == .object(["api_log": .string("keys")]))
    }

    @Test("sonar64")
    func sonar() async throws {
        let st = MockTransport(json: #"{"version":"1","running":true,"key_set":true,"participate":true,"node":{"node_id":"n1","registered":true,"paused":"quiet","sent_today":4,"plan_expires":"2026-10-28T10:00:00Z"},"me":{"lat":1},"trust":{"level":"stable","class":"c","need_days":7,"uptime":0.9},"public_url":"https://ipv64.net/x"}"#)
        let status = try await Node64.mock(st).sonar64.status()
        #expect(status.node?.paused == .quiet)
        #expect(status.node?.nodeID == "n1")
        #expect(status.trust?.level == .stable)
        #expect(status.trust?.class == "c")
        #expect(status.publicURL == "https://ipv64.net/x")
        #expect(last(st).1 == "/sonar64/status")

        let rc = MockTransport(json: #"{"results":[{"at":"2026-10-27T10:00:00Z","target":"a_x","method":"icmp","fam":4,"sent":3,"recv":3,"min":1,"avg":2,"max":3,"loss":0}],"inbound":[{"from":"abcd1234","name":"n","fam":6,"count":2,"at":"2026-10-27T10:00:00Z"}],"responder":true}"#)
        let recent = try await Node64.mock(rc).sonar64.recent(n: 20)
        #expect(recent.results?.first?.method == .icmp)
        #expect(recent.inbound?.first?.count == 2)
        #expect(last(rc).1 == "/sonar64/recent?n=20")

        let ib = MockTransport(json: #"{"ready":true,"rows":[{"from":"x","trust":"anchor","fam":4,"method":"udp","avg":1.5,"loss":0.1,"at":"2026-10-27T10:00:00Z"}]}"#)
        let inbound = try await Node64.mock(ib).sonar64.inbound(since: Date(timeIntervalSince1970: 0))
        #expect(inbound.rows?.first?.trust == .anchor)
        #expect(last(ib).1.hasPrefix("/sonar64/inbound?since=1970-01-01"))

        let se = MockTransport(json: #"{"participate":true,"measured":false,"budget":"normal","quiet":"23-6","name":"n","lat":1.5,"lon":2.5,"access":"fiber","device":""}"#)
        #expect(try await Node64.mock(se).sonar64.settings().access == .fiber)
        #expect(last(se).1 == "/sonar64/settings")

        let up = MockTransport(json: #"{"participate":true}"#)
        _ = try await Node64.mock(up).sonar64.updateSettings(.init(participate: true, budget: .generous, clearLocation: true))
        #expect(last(up).0 == "PUT")
        #expect(last(up).2 == .object(["participate": .bool(true), "budget": .string("grosszuegig"), "clear_location": .bool(true)]))
    }

    @Test("link by code")
    func linkCode() async throws {
        let s = MockTransport(status: 201, json: #"{"code":"ABC","expires_at":"2026-10-27T10:00:00Z","hub":"hub"}"#)
        let code = try await Node64.mock(s).link.startCodeLink()
        #expect(code.code == "ABC")
        #expect(last(s).0 == "POST" && last(s).1 == "/link/start")

        let st = MockTransport(json: #"{"linked":false,"connected":false,"code":"ABC","hub":"hub","requesting":true}"#)
        #expect(try await Node64.mock(st).link.codeStatus().requesting == true)
        #expect(last(st).0 == "GET" && last(st).1 == "/link/status")

        let c = MockTransport(status: 204, body: Data())
        try await Node64.mock(c).link.cancelCodeLink()
        #expect(last(c).0 == "POST" && last(c).1 == "/link/cancel")
    }

    @Test("cluster conflicts")
    func clusterConflicts() async throws {
        let u = MockTransport(json: #"{"username":"bob","chosen":"u1","dropped":[{"uid":"u2","node_id":"n2","own":false}]}"#)
        let ur = try await Node64.mock(u).cluster.resolveUserConflict(uid: "u1")
        #expect(ur.dropped?.first?.nodeID == "n2")
        #expect(last(u).1 == "/group/users")
        #expect(last(u).2 == .object(["uid": .string("u1")]))

        let a = MockTransport(json: #"{"chosen":"tp","dropped":[{"thumbprint":"t2","node_id":"n2","email":"a@b.c"}]}"#)
        let ar = try await Node64.mock(a).cluster.resolveACMEConflict(thumbprint: "tp")
        #expect(ar.dropped?.first?.email == "a@b.c")
        #expect(last(a).1 == "/group/acme")
        #expect(last(a).2 == .object(["thumbprint": .string("tp")]))

        let g = try IPv64Coding.makeDecoder().decode(Node64.ClusterGroup.self, from: Data(#"{"user_conflicts":[{"a":1}],"acme_accounts":[]}"#.utf8))
        #expect(g.userConflicts != nil && g.acmeAccounts == .array([]))
    }

    @Test("dyndns cluster")
    func dyndnsCluster() async throws {
        let t = MockTransport(json: #"{"preferred_node":"n2"}"#)
        let node = try await Node64.mock(t).dyndns.setPreferredNode("n2")
        #expect(node == "n2")
        #expect(last(t).0 == "PUT" && last(t).1 == "/dyndns/cluster")
        #expect(last(t).2 == .object(["preferred_node": .string("n2")]))

        let s = try IPv64Coding.makeDecoder().decode(Node64.DynDNSStatus.self, from: Data(#"{"cluster":{"leader":"n1","this_node":"n1","preferred_node":""}}"#.utf8))
        #expect(s.cluster?.thisNode == "n1")
    }
}
