import Foundation
import Testing
@testable import IPv64

@Suite("Node64 Monitor64 hosts, access, agent, traps")
struct Monitor64HostsTests {
    private func request(_ t: MockTransport) -> (String, String) {
        (t.lastRequest?.httpMethod ?? "", t.lastRequest?.nodeRelativePath ?? "")
    }

    @Test("overview list and host detail decode")
    func listAndGet() async throws {
        let list = MockTransport(json: """
        [{"uid":"h1","name":"nas","address":"10.0.0.2","kind":"nas","state":"warn","view":"maintenance","problems":2,
          "maint":{"reason":"Update","end":"2026-11-11T12:00:00Z"},"meters":[{"label":"cpu","value":12.5,"state":"ok"}],
          "checked":"2026-11-11T10:00:00Z","has_cpu":true}]
        """)
        let hosts = try await Node64.mock(list).monitor64.hosts.list()
        #expect(request(list) == ("GET", "/monitor64/hosts"))
        #expect(hosts.first?.view == .maintenance)
        #expect(hosts.first?.maint?.reason == "Update")
        #expect(hosts.first?.meters?.first?.label == .cpu)

        let detail = MockTransport(json: """
        {"host":{"uid":"h1","name":"nas","address":"10.0.0.2","kind":"future-kind","tags":["a"],"interval_sec":60,"created_at":"2026-11-01T08:00:00Z"},
         "state":"crit","view":"unreachable","running":true,
         "services":[{"key":"cpu","name":"CPU","state":"warn","adopted":1,"category":"system","guest":false,"primary":0,
           "metrics":[{"name":"util","value":91.5,"unit":"%","rule":"cpu","status":{"state":"warn","threshold":80,"pending_limit":"off"}}],
           "levels":{"kind":"cpu","std":{"warn":80,"crit":"off","for":300},"eff":{"kind":"cpu","origin":{"warn":"default","crit":"override"},"override":-1}},
           "ack":{"by":{"kind":"user","name":"seb"},"at":"2026-11-11T09:00:00Z"}}],
         "accesses":[{"uid":"a1","type":"snmp","config":{"port":161,"snmp_version":"2c","custom":[{"oid":"1.3","name":"x"}],"traps":true},"secret_set":true,"ok":true,
           "agent":{"uid":"h1","state":"pending","latest":"1.2.3"}}],
         "new":[{"uid":"s1","key":"fs:/","adopted":0,"soll":"run"}],
         "charts":[{"id":"cpu","unit":"%","series":[{"label":"CPU","svc":"cpu","metric":"util"}]}]}
        """)
        let d = try await Node64.mock(detail).monitor64.hosts.get("h1")
        #expect(request(detail) == ("GET", "/monitor64/hosts/h1"))
        #expect(d.host?.kind == Node64.Monitor64HostKind(rawValue: "future-kind"))
        #expect(d.services?.first?.levels?.std?.warn == .value(80))
        #expect(d.services?.first?.levels?.std?.crit == Node64.Monitor64Limit.off)
        #expect(d.services?.first?.metrics?.first?.status?.pendingLimit == .off)
        #expect(d.services?.first?.levels?.eff?.origin?["crit"] == .deviation)
        #expect(d.accesses?.first?.config?.snmpVersion == .v2c)
        #expect(d.accesses?.first?.secretSet == true)
        #expect(d.accesses?.first?.agent?.state == .pending)
        #expect(d.new?.first?.soll == .run)
        #expect(d.charts?.first?.series?.first?.svc == "cpu")
    }

    @Test("create, update and delete host")
    func createUpdateDelete() async throws {
        let t = MockTransport(status: 201, json: #"{"uid":"h2"}"#)
        let input = Node64.Monitor64HostCreate(
            name: "box", address: "10.0.0.5", kind: .linuxAgent, tags: ["x"],
            accesses: [.init(type: .agent, config: .init(mode: .push), secret: "s3cret", enabled: true)],
            services: [.init(key: "cpu", isDefault: true)], adopt: ["cpu"]
        )
        let created = try await Node64.mock(t).monitor64.hosts.create(input)
        #expect(created.uid == "h2")
        #expect(request(t) == ("POST", "/monitor64/hosts"))
        #expect(t.lastRequest?.jsonBody == .object([
            "name": .string("box"), "address": .string("10.0.0.5"), "kind": .string("linux-agent"), "tags": .array([.string("x")]),
            "accesses": .array([.object(["type": .string("agent"), "config": .object(["mode": .string("push")]),
                                         "secret": .string("s3cret"), "enabled": .bool(true)])]),
            "services": .array([.object(["key": .string("cpu"), "default": .bool(true)])]), "adopt": .array([.string("cpu")]),
        ]))

        let u = MockTransport(json: #"{"uid":"h2"}"#)
        _ = try await Node64.mock(u).monitor64.hosts.update("h2", .init(name: "box", address: "10.0.0.6"))
        #expect(request(u) == ("PUT", "/monitor64/hosts/h2"))
        #expect(u.lastRequest?.jsonBody == .object(["name": .string("box"), "address": .string("10.0.0.6")]))

        let d = MockTransport(json: #"{"ok":true,"series_deleted":12}"#)
        let deleted = try await Node64.mock(d).monitor64.hosts.delete("h2", deleteHistory: true)
        #expect(deleted.seriesDeleted == 12)
        #expect(request(d) == ("DELETE", "/monitor64/hosts/h2?history=delete"))
        _ = try await Node64.mock(d).monitor64.hosts.delete("h2")
        #expect(request(d).1 == "/monitor64/hosts/h2")
    }

    @Test("access endpoints")
    func accessEndpoints() async throws {
        let t = MockTransport(status: 201, json: #"{"uid":"a9","type":"pve","config":{"url":"https://pve:8006","token_id":"u@pam!t"},"enabled":true,"secret_set":true}"#)
        let node = Node64.mock(t)
        let created = try await node.monitor64.hosts.createAccess(host: "h1", .init(type: .pve, config: .init(url: "https://pve:8006"), secret: "tok"))
        #expect(request(t) == ("POST", "/monitor64/hosts/h1/access"))
        #expect(created.config?.tokenID == "u@pam!t")
        #expect(created.secretSet == true)

        _ = try await node.monitor64.access.update("a9", .init(clearSecret: true, hostkey: "reset"))
        #expect(request(t) == ("PUT", "/monitor64/access/a9"))
        #expect(t.lastRequest?.jsonBody == .object(["clear_secret": .bool(true), "hostkey": .string("reset")]))

        let ok = MockTransport(json: #"{"ok":true}"#)
        let n2 = Node64.mock(ok)
        _ = try await n2.monitor64.access.delete("a9")
        #expect(request(ok) == ("DELETE", "/monitor64/access/a9"))
        _ = try await n2.monitor64.access.resetHostKey("a9")
        #expect(request(ok) == ("POST", "/monitor64/access/a9/hostkey-reset"))

        let test = MockTransport(json: #"{"ok":false,"error":"timeout","ms":20000,"need_confirm":true,"nodes":[{"name":"pve1","id":1,"online":true,"local":true}],"profiles":[{"id":"p","verified":true}],"services":[{"key":"cpu","default":true}]}"#)
        let n3 = Node64.mock(test)
        let r = try await n3.monitor64.access.test("a9")
        #expect(request(test) == ("POST", "/monitor64/access/a9/test"))
        #expect(test.lastRequest?.httpBody == nil)
        #expect(r.ok == false && r.needConfirm == true)
        #expect(r.nodes?.first?.local == true)
        #expect(r.services?.first?.isDefault == true)
        _ = try await n3.monitor64.access.test("a9", changes: .init(config: .init(port: 22)))
        #expect(test.lastRequest?.jsonBody == .object(["config": .object(["port": .number(22)])]))
    }

    @Test("connection test, node address and push token")
    func wizard() async throws {
        let t = MockTransport(json: #"{"ok":true,"fingerprint":"SHA256:abc","services":[]}"#)
        let result = try await Node64.mock(t).monitor64.test(.init(address: "10.0.0.2", access: .init(type: .ssh), accessUID: "a1"))
        #expect(request(t) == ("POST", "/monitor64/test"))
        #expect(t.lastRequest?.jsonBody == .object(["address": .string("10.0.0.2"), "access": .object(["type": .string("ssh")]), "access_uid": .string("a1")]))
        #expect(result.fingerprint == "SHA256:abc")

        let a = MockTransport(json: #"{"addr":"10.0.0.1"}"#)
        let addr = try await Node64.mock(a).monitor64.nodeAddress(target: "nas.lan")
        #expect(addr == "10.0.0.1")
        #expect(request(a) == ("GET", "/monitor64/nodeaddr?target=nas.lan"))

        let p = MockTransport(json: #"{"token":"tok","port":6464}"#)
        let token = try await Node64.mock(p).monitor64.pushToken()
        #expect(token.port == 6464)
        #expect(request(p) == ("GET", "/monitor64/push/token"))
    }

    @Test("discover, adopt, remove and service update")
    func services() async throws {
        let d = MockTransport(json: #"{"added":1,"new":2,"vanished":3}"#)
        let r = try await Node64.mock(d).monitor64.hosts.discover("h1")
        #expect(r.vanished == 3)
        #expect(request(d) == ("POST", "/monitor64/hosts/h1/discover"))

        let c = MockTransport(json: #"{"changed":2}"#)
        let node = Node64.mock(c)
        let adopted = try await node.monitor64.hosts.adoptServices(host: "h1", keys: ["a", "b"], state: .ignore)
        #expect(adopted.changed == 2)
        #expect(request(c) == ("POST", "/monitor64/hosts/h1/services/adopt"))
        #expect(c.lastRequest?.jsonBody == .object(["keys": .array([.string("a"), .string("b")]), "state": .number(-1)]))
        _ = try await node.monitor64.hosts.removeServices(host: "h1", keys: ["a"])
        #expect(request(c) == ("POST", "/monitor64/hosts/h1/services/remove"))
        #expect(c.lastRequest?.jsonBody == .object(["keys": .array([.string("a")])]))

        let ok = MockTransport(json: #"{"ok":true}"#)
        let update = Node64.Monitor64ServiceUpdate(
            key: "cpu", name: "", soll: .run,
            rules: ["cpu": .init(rule: .init(warn: .value(70), crit: .off, forSeconds: 60), scope: .kind)], reset: false
        )
        _ = try await Node64.mock(ok).monitor64.hosts.updateService(host: "h1", update)
        #expect(request(ok) == ("PUT", "/monitor64/hosts/h1/service"))
        #expect(ok.lastRequest?.jsonBody == .object([
            "key": .string("cpu"), "name": .string(""), "soll": .string("run"), "reset": .bool(false),
            "rules": .object(["cpu": .object(["scope": .string("kind"),
                "rule": .object(["warn": .number(70), "crit": .string("off"), "for": .number(60)])])]),
        ]))
    }

    @Test("traps and agent")
    func trapsAndAgent() async throws {
        let ht = MockTransport(json: #"{"list":[{"time":"2026-11-11T10:00:00Z","trap_oid":"1.3.6","handled":true,"varbinds":[{"oid":"1.3","type":"str","value":"x"}]}],"pending":1,"total":5}"#)
        let traps = try await Node64.mock(ht).monitor64.hosts.traps("h1")
        #expect(request(ht) == ("GET", "/monitor64/hosts/h1/traps"))
        #expect(traps.list?.first?.varbinds?.first?.value == "x")
        #expect(traps.pending == 1)

        let ok = MockTransport(json: #"{"ok":true}"#)
        let node = Node64.mock(ok)
        _ = try await node.monitor64.hosts.resetTraps("h1")
        #expect(request(ok) == ("POST", "/monitor64/hosts/h1/traps/reset"))
        _ = try await node.monitor64.traps.clearUnknown()
        #expect(request(ok) == ("DELETE", "/monitor64/traps/unknown"))

        let ts = MockTransport(json: #"{"active":1,"running":true,"port":162,"engine_id":"80","stats":{"received":9,"rate_limited":1},"unknown":[{"addr":"1.2.3.4","count":2,"first":"2026-11-11T10:00:00Z"}]}"#)
        let status = try await Node64.mock(ts).monitor64.traps.status()
        #expect(request(ts) == ("GET", "/monitor64/traps"))
        #expect(status.stats?.rateLimited == 1)
        #expect(status.unknown?.first?.count == 2)

        let ag = MockTransport(json: """
        {"version":"1.2.3","running":true,"source":{"bases":["https://a"],"checked":"2026-11-11T10:00:00Z","error":"x"},
         "files":[{"key":"linux-amd64","cached":true}],"scripts":[{"name":"install.sh","size":10}],
         "hosts":[{"uid":"h1","state":"elsewhere","node":"n2"}],"events":[{"kind":"agent_update","host":"nas","actor":{"kind":"system"}}]}
        """)
        let n2 = Node64.mock(ag)
        let agent = try await n2.monitor64.agent.get()
        #expect(request(ag) == ("GET", "/monitor64/agent"))
        #expect(agent.source?.error == "x")
        #expect(agent.hosts?.first?.state == .elsewhere)
        #expect(agent.events?.first?.actor?.kind == .system)
        _ = try await n2.monitor64.agent.refresh()
        #expect(request(ag) == ("POST", "/monitor64/agent/refresh"))

        let au = MockTransport(json: #"{"uid":"h1","autoupdate":false}"#)
        let setting = try await Node64.mock(au).monitor64.hosts.updateAgent(host: "h1", autoupdate: false)
        #expect(setting.autoupdate == false)
        #expect(request(au) == ("PUT", "/monitor64/hosts/h1/agent"))
        #expect(au.lastRequest?.jsonBody == .object(["autoupdate": .bool(false)]))

        let started = MockTransport(status: 202, json: #"{"ok":true,"version":"1.2.3"}"#)
        let s = try await Node64.mock(started).monitor64.hosts.updateAgentNow(host: "h1")
        #expect(s.version == "1.2.3")
        #expect(request(started) == ("POST", "/monitor64/hosts/h1/agent/update"))
    }

    @Test("errors carry the message")
    func error() async throws {
        let t = MockTransport(status: 400, json: #"{"error":"agent_current","message":"Agent ist aktuell"}"#)
        do {
            _ = try await Node64.mock(t).monitor64.hosts.updateAgentNow(host: "h1")
            Issue.record("expected failure")
        } catch let error as Node64Error {
            guard case .api(let api) = error else { Issue.record("wrong error"); return }
            #expect(api.status == 400 && api.error == "agent_current" && api.text == "Agent ist aktuell")
        }
    }
}
