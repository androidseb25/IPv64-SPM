import Foundation
import Testing
@testable import IPv64

@Suite("Node64 Monitor64 cluster, overview, series, settings")
struct Monitor64ClusterTests {
    private func req(_ t: MockTransport) -> (String, String, JSONValue?) {
        (t.lastRequest?.httpMethod ?? "", t.lastRequest?.nodeRelativePath ?? "", t.lastRequest?.jsonBody)
    }

    private let keysJSON = #"{"fingerprint":"SHA256:abc","authorized_key":"ssh-ed25519 AAAA","cluster":true,"at":"2026-11-11T10:00:00Z","old_keys":["SHA256:old"],"pending":[{"access_uid":"a1","host_uid":"h1","host_name":"nas","type":"ssh","tries":2,"last_try":"2026-11-11T10:05:00Z","error":"denied","manual":true}],"running":true}"#

    @Test("overview")
    func overview() async throws {
        let t = MockTransport(json: #"{"counts":{"ok":5,"warn":1,"crit":2,"unknown":0},"problems":[{"host_uid":"h1","host":"nas","key":"","name":"Host","state":"crit","detail":"down","since":"2026-11-11T09:00:00Z","acked":false,"maint":false,"unreach":true}],"recent":[{"kind":"maint_end","host_uid":"h1","host":"nas","name":"x","text":"t","at":"2026-11-11T09:30:00Z"}],"groups":["g"],"unreachable":1,"services":8,"open_unacked":2,"running":true}"#)
        let o = try await Node64.mock(t).monitor64.overview()
        #expect(req(t).0 == "GET" && req(t).1 == "/monitor64/overview")
        #expect(o.counts?.crit == 2 && o.openUnacked == 2 && o.running == true)
        #expect(o.problems?.first?.state == .crit && o.problems?.first?.hostUID == "h1")
        #expect(o.recent?.first?.kind == .maintEnd && o.recent?.first?.at != nil)
    }

    @Test("sparks")
    func sparks() async throws {
        let t = MockTransport(json: #"{"h1":[1.5,2,3]}"#)
        let s = try await Node64.mock(t).monitor64.sparks(host: "h1")
        #expect(req(t).0 == "GET" && req(t).1 == "/monitor64/sparks?host=h1")
        #expect(s["h1"] == [1.5, 2, 3])
        _ = try await Node64.mock(t).monitor64.sparks()
        #expect(req(t).1 == "/monitor64/sparks")
    }

    @Test("series")
    func series() async throws {
        let t = MockTransport(json: #"{"from":100,"to":200,"series":[{"s":"cpu|load","res":"5m","step":300,"points":[{"t":100,"min":1,"avg":1.5,"max":2,"s":300}]}],"cluster":[{"node":"n2","name":"B","ok":false,"missing":true}]}"#)
        let s = try await Node64.mock(t).monitor64.series(host: "h1", series: ["cpu|load", "mem|used"], range: .week, offset: 1, points: 100)
        #expect(req(t).0 == "GET")
        #expect(req(t).1 == "/monitor64/series?host=h1&s=cpu%7Cload&s=mem%7Cused&range=7d&off=1&points=100")
        #expect(s.series?.first?.points?.first?.avg == 1.5 && s.series?.first?.step == 300)
        #expect(s.cluster?.first?.missing == true && s.to == 200)
    }

    @Test("status and settings")
    func settings() async throws {
        let st = #"{"version":"1.0","uptime":"3h2m1s","scheduler":{"jobs":4,"running":1,"workers":8,"runs":99,"late":0},"history_mb":1.5,"loadgen_hosts":0,"loadgen_points_per_sec":0,"heap_mb":20.5,"goroutines":30}"#
        let t = MockTransport(json: st)
        let status = try await Node64.mock(t).monitor64.status()
        #expect(req(t).1 == "/monitor64/status")
        #expect(status.scheduler?.workers == 8 && status.historyMB == 1.5 && status.goroutines == 30)

        let g = MockTransport(json: #"{"interval":60,"workers":16,"retention_raw_hours":48,"retention_5m_days":30,"retention_1h_days":365,"hosts":3,"services":9,"status":\#(st),"port":7070,"public_key":"ssh-ed25519 X","fingerprint":"SHA256:f","trap_port":162,"push_port":7071,"push":{"listening":[":7071"],"stats":{"Tokens":2,"Pending":1,"Parked":0}}}"#)
        let s = try await Node64.mock(g).monitor64.settings()
        #expect(req(g).0 == "GET" && req(g).1 == "/monitor64/settings")
        #expect(s.retention5mDays == 30 && s.push?.stats?.tokens == 2 && s.status?.version == "1.0" && s.pushPort == 7071)

        let p = MockTransport(json: #"{"ok":true}"#)
        _ = try await Node64.mock(p).monitor64.updateSettings(.init(interval: 60, workers: 8, pushPort: 7072))
        #expect(req(p).0 == "PUT" && req(p).1 == "/monitor64/settings")
        #expect(req(p).2 == .object(["interval": .number(60), "workers": .number(8), "push_port": .number(7072)]))
    }

    @Test("cluster read endpoints")
    func clusterReads() async throws {
        let host = #"{"uid":"h1","name":"nas","owner":"n1","owner_name":"A","preferred":"n1","backups":["n2"],"role":"report","reachable":true}"#
        let t = MockTransport(json: #"{"active":true,"self":"n1","majority":true,"total":2,"connected":2,"nodes":[{"id":"n1","name":"A","self":true,"online":true,"stable":true}],"hosts":[\#(host)],"key":\#(keysJSON)}"#)
        let c = try await Node64.mock(t).monitor64.cluster.get()
        #expect(req(t).0 == "GET" && req(t).1 == "/monitor64/cluster")
        #expect(c.isSelf == "n1" && c.nodes?.first?.isSelf == true && c.hosts?.first?.role == .report)
        #expect(c.key?.pending?.first?.manual == true && c.key?.pending?.first?.lastTry != nil)

        let v = MockTransport(json: #"{"active":true,"self":"n1","self_name":"A","refs":{"h1":{"node":"n2","name":"B","here":false,"reporting":true,"reachable":true,"note":"no_data","at":"2026-11-11T10:00:00Z"}},"orphans":[{"uid":"h2","name":"x","address":"10.0.0.2","reason":"node_gone","node":"n3","node_name":"C"}]}"#)
        let views = try await Node64.mock(v).monitor64.cluster.views(host: "h1")
        #expect(req(v).1 == "/monitor64/cluster/views?host=h1")
        #expect(views.refs?["h1"]?.note == "no_data" && views.orphans?.first?.reason == .nodeGone && views.selfName == "A")

        let i = MockTransport(json: #"{"active":true,"self":"n1","majority":false,"nodes":[],"host":\#(host),"ref":{"node":"n1"},"events":[]}"#)
        let info = try await Node64.mock(i).monitor64.cluster.host("h1")
        #expect(req(i).0 == "GET" && req(i).1 == "/monitor64/cluster/hosts/h1")
        #expect(info.host?.uid == "h1" && info.majority == false && info.events?.isEmpty == true)

        let o = MockTransport(json: #"{"active":true,"self":"n1","orphans":[{"uid":"h2"}]}"#)
        let orphans = try await Node64.mock(o).monitor64.cluster.orphans()
        #expect(req(o).1 == "/monitor64/cluster/orphans" && orphans.orphans?.first?.uid == "h2")
    }

    @Test("cluster host update and reach")
    func hostWrites() async throws {
        let t = MockTransport(json: #"{"uid":"h1","preferred_node":"n2","backup_nodes":["n3"]}"#)
        let r = try await Node64.mock(t).monitor64.cluster.updateHost("h1", .init(preferredNode: "n2", backupNodes: ["n3"]))
        #expect(req(t).0 == "PUT" && req(t).1 == "/monitor64/cluster/hosts/h1")
        #expect(req(t).2 == .object(["preferred_node": .string("n2"), "backup_nodes": .array([.string("n3")])]))
        #expect(r.preferredNode == "n2" && r.backupNodes == ["n3"])

        let p = MockTransport(json: #"{"nodes":[{"node":"n1","name":"A","self":true,"ok":false,"error":"x","accesses":[{"access":"a1","type":"ssh","ok":true,"ms":12,"skip":false}]}]}"#)
        let reach = try await Node64.mock(p).monitor64.cluster.testReach("h1")
        #expect(req(p).0 == "POST" && req(p).1 == "/monitor64/cluster/hosts/h1/reach")
        #expect(reach.nodes?.first?.accesses?.first?.ms == 12 && reach.nodes?.first?.isSelf == true)
    }

    @Test("cluster keys")
    func keys() async throws {
        let t = MockTransport(json: keysJSON)
        let c = Node64.mock(t).monitor64.cluster
        let k = try await c.keys()
        #expect(req(t).0 == "GET" && req(t).1 == "/monitor64/cluster/keys")
        #expect(k.fingerprint == "SHA256:abc" && k.authorizedKey == "ssh-ed25519 AAAA" && k.oldKeys == ["SHA256:old"] && k.running == true)
        _ = try await c.rotateKey()
        #expect(req(t).0 == "POST" && req(t).1 == "/monitor64/cluster/keys/rotate")
        _ = try await c.retryKeys()
        #expect(req(t).0 == "POST" && req(t).1 == "/monitor64/cluster/keys/retry")
        _ = try await c.retireKeys()
        #expect(req(t).0 == "POST" && req(t).1 == "/monitor64/cluster/keys/retire")
        _ = try await c.confirmKey(accessUID: "a1")
        #expect(req(t).1 == "/monitor64/cluster/keys/confirm" && req(t).2 == .object(["access_uid": .string("a1")]))
    }

    @Test("orphans assign and remove")
    func orphanWrites() async throws {
        let t = MockTransport(json: #"{"done":1,"orphans":[{"uid":"h3"}]}"#)
        let c = Node64.mock(t).monitor64.cluster
        let a = try await c.assignOrphans(.init(uids: ["h2"]))
        #expect(req(t).0 == "POST" && req(t).1 == "/monitor64/cluster/orphans/assign")
        #expect(req(t).2 == .object(["uids": .array([.string("h2")])]))
        #expect(a.done == 1 && a.orphans?.first?.uid == "h3")
        _ = try await c.removeOrphans(.init(all: true))
        #expect(req(t).1 == "/monitor64/cluster/orphans/remove" && req(t).2 == .object(["all": .bool(true)]))
    }
}
