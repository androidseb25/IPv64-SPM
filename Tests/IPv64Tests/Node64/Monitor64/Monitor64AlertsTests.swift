import Foundation
import Testing
@testable import IPv64

@Suite("Monitor64 alerts: problems, rules, notify, maintenance")
struct Monitor64AlertsTests {
    private func last(_ t: MockTransport) -> (String, String, JSONValue?) {
        (t.lastRequest?.httpMethod ?? "", t.lastRequest?.nodeRelativePath ?? "", t.lastRequest?.jsonBody)
    }
    private let ok = #"{"ok":true}"#

    @Test("problems")
    func problems() async throws {
        let json = #"{"problems":[{"uid":"p1","host_uid":"h1","key":"cpu","state":"crit","worst":"crit","opened":"2026-11-10T10:00:00Z","how":"user","closed_by":{"kind":"user","name":"admin"},"ack":{"by":{"kind":"api","name":"k"},"comment":"on it"},"notified":["default"],"host":"nas","host_gone":false,"name":"CPU","duration":60,"channels":["Mail"]}],"people":[{"kind":"system"}],"counts":{"open":1,"closed":2}}"#
        let t = MockTransport(json: json)
        let list = try await Node64.mock(t).monitor64.problems.list(status: .all, range: .day, who: "api", query: "cpu", host: "h1")
        #expect(list.problems?.first?.state == .crit)
        #expect(list.problems?.first?.hostGone == false)
        #expect(list.counts?.closed == 2)
        let url = t.lastRequest?.url?.absoluteString ?? ""
        #expect(last(t).0 == "GET" && last(t).1.hasPrefix("/monitor64/problems?"))
        for part in ["status=all", "range=24h", "who=api", "q=cpu", "host=h1"] { #expect(url.contains(part)) }

        let d = MockTransport(json: #"{"problem":{"uid":"p1","how":"auto"},"events":[],"channels":{"3":"Mail"}}"#)
        let detail = try await Node64.mock(d).monitor64.problems.get("p1")
        #expect(detail.channels?["3"] == "Mail")
        #expect(detail.problem?.how == .auto)
        #expect(last(d).1 == "/monitor64/problems/p1")

        let csv = MockTransport(status: 200, body: Data("\u{FEFF}a;b\n".utf8), headers: ["Content-Type": "text/csv"])
        let text = try await Node64.mock(csv).monitor64.problems.csv(status: .closed)
        #expect(text.hasSuffix("a;b\n"))
        #expect(last(csv).1 == "/monitor64/problems.csv?status=closed")

        let a = MockTransport(json: ok)
        _ = try await Node64.mock(a).monitor64.problems.perform(.init(host: "h1", action: .comment, comment: "hi"))
        #expect(last(a).0 == "POST" && last(a).1 == "/monitor64/problems/action")
        #expect(last(a).2 == .object(["host": .string("h1"), "action": .string("comment"), "comment": .string("hi")]))
    }

    @Test("rules")
    func rules() async throws {
        let json = #"{"kinds":[{"kind":"cpu","group":"system","unit":"%","factor":1,"down":false}],"defaults":{"cpu":{"warn":80,"crit":"off","for":300}},"std":{},"overrides":[{"uid":"o1","position":0,"target_type":"tag","target":"prod","kind":"cpu","data":{"warn":70},"rule":{"warn":70},"effect":{"services":2,"hosts":["nas"],"shadow":{"0":["x"]},"before":{"warn":80,"crit":90},"after":{"warn":70,"crit":90}}}],"own":[{"host_uid":"h1","host":"nas","key":"","kind":"cpu"}],"targets":{"groups":["a"],"tags":["prod"]}}"#
        let t = MockTransport(json: json)
        let r = try await Node64.mock(t).monitor64.rules.get()
        #expect(r.kinds?.first?.kind == "cpu")
        #expect(r.overrides?.first?.targetType == .tag)
        #expect(r.overrides?.first?.effect?.after?.warn == 70)
        #expect(r.own?.first?.hostUID == "h1")
        #expect(r.targets?.tags == ["prod"])
        #expect(last(t).0 == "GET" && last(t).1 == "/monitor64/rules")

        let s = MockTransport(json: #"{"ok":true,"changed":["cpu"]}"#)
        let res = try await Node64.mock(s).monitor64.rules.updateStandard(["cpu": try JSONDecoder().decode(Node64.Monitor64Rule.self, from: Data(#"{"warn":70}"#.utf8))])
        #expect(res.changed == ["cpu"])
        #expect(last(s).0 == "PUT" && last(s).1 == "/monitor64/rules/std")
        #expect(last(s).2 == .object(["rules": .object(["cpu": .object(["warn": .number(70)])])]))

        let rule = try JSONDecoder().decode(Node64.Monitor64Rule.self, from: Data(#"{"crit":90}"#.utf8))
        let input = Node64.Monitor64RuleOverrideInput(targetType: .group, target: "g", kind: "cpu", rule: rule)
        let p = MockTransport(json: #"{"services":1}"#)
        let eff = try await Node64.mock(p).monitor64.rules.preview(input, replacing: "o1")
        #expect(eff.services == 1)
        #expect(last(p).0 == "POST" && last(p).1 == "/monitor64/rules/preview")
        #expect(last(p).2 == .object(["target_type": .string("group"), "target": .string("g"), "kind": .string("cpu"), "rule": .object(["crit": .number(90)]), "uid": .string("o1")]))

        let c = MockTransport(json: #"{"uid":"o2"}"#)
        #expect(try await Node64.mock(c).monitor64.rules.createOverride(input) == "o2")
        #expect(last(c).0 == "POST" && last(c).1 == "/monitor64/rules/overrides")
        let u = MockTransport(json: #"{"uid":"o2"}"#)
        _ = try await Node64.mock(u).monitor64.rules.updateOverride("o2", input)
        #expect(last(u).0 == "PUT" && last(u).1 == "/monitor64/rules/overrides/o2")
        let d = MockTransport(json: ok)
        try await Node64.mock(d).monitor64.rules.deleteOverride("o2")
        #expect(last(d).0 == "DELETE" && last(d).1 == "/monitor64/rules/overrides/o2")
        let m = MockTransport(json: ok)
        try await Node64.mock(m).monitor64.rules.moveOverride("o2", .up)
        #expect(last(m).0 == "POST" && last(m).1 == "/monitor64/rules/overrides/o2/move")
        #expect(last(m).2 == .object(["dir": .number(-1)]))
    }

    @Test("notify")
    func notify() async throws {
        let json = #"{"config":{"channels":[{"id":"default","warn":true,"crit":true}],"remind_warn":0,"remind_crit":86400,"crit_in_quiet":true},"channels":[{"id":3,"type":"mail","name":"Mail","enabled":true,"default":true}],"overrides":[{"uid":"n1","position":0,"target_type":"group","target":"g","data":{},"notify":{"channels":[{"id":"3","crit":true}],"replace":false,"only_crit":true,"remind_crit":3600}}],"quiet":{"enabled":true,"from":"22:00","to":"06:00","days":"all"},"targets":{"groups":["g"],"tags":[]}}"#
        let t = MockTransport(json: json)
        let n = try await Node64.mock(t).monitor64.notify.get()
        #expect(n.config?.remindCrit == 86400)
        #expect(n.channels?.first?.isDefault == true)
        #expect(n.overrides?.first?.notify?.onlyCrit == true)
        #expect(n.quiet?.from == "22:00")
        #expect(last(t).0 == "GET" && last(t).1 == "/monitor64/notify")

        let u = MockTransport(json: ok)
        try await Node64.mock(u).monitor64.notify.update(.init(channels: [.init(id: "default", warn: true)], remindCrit: 3600))
        #expect(last(u).0 == "PUT" && last(u).1 == "/monitor64/notify")
        #expect(last(u).2 == .object(["channels": .array([.object(["id": .string("default"), "warn": .bool(true)])]), "remind_crit": .number(3600)]))

        let te = MockTransport(json: #"{"ok":true,"channels":2}"#)
        #expect(try await Node64.mock(te).monitor64.notify.test().channels == 2)
        #expect(last(te).0 == "POST" && last(te).1 == "/monitor64/notify/test")

        let input = Node64.Monitor64NotifyOverrideInput(targetType: .tag, target: "prod", replace: true, onlyCrit: true)
        let c = MockTransport(json: #"{"uid":"n2"}"#)
        #expect(try await Node64.mock(c).monitor64.notify.createOverride(input) == "n2")
        #expect(last(c).0 == "POST" && last(c).1 == "/monitor64/notify/overrides")
        #expect(last(c).2 == .object(["target_type": .string("tag"), "target": .string("prod"), "replace": .bool(true), "only_crit": .bool(true)]))
        let p = MockTransport(json: #"{"uid":"n2"}"#)
        _ = try await Node64.mock(p).monitor64.notify.updateOverride("n2", input)
        #expect(last(p).0 == "PUT" && last(p).1 == "/monitor64/notify/overrides/n2")
        let d = MockTransport(json: ok)
        try await Node64.mock(d).monitor64.notify.deleteOverride("n2")
        #expect(last(d).0 == "DELETE" && last(d).1 == "/monitor64/notify/overrides/n2")
        let m = MockTransport(json: ok)
        try await Node64.mock(m).monitor64.notify.moveOverride("n2", .down)
        #expect(last(m).1 == "/monitor64/notify/overrides/n2/move")
        #expect(last(m).2 == .object(["dir": .number(1)]))
    }

    @Test("maintenance")
    func maintenance() async throws {
        let json = #"{"items":[{"uid":"m1","title":"Update","hosts":["h1"],"start":"2026-11-12T01:00:00Z","end":"2026-11-12T02:00:00Z","recur":{"days":[0],"from":"01:00","to":"02:00"},"by":{"kind":"user","name":"admin"},"status":"planned","running":false,"start_local":"2026-11-12T02:00"}],"hosts":[{"uid":"h1","name":"nas","group":"g","kind":"linux"}],"targets":{"groups":["g"],"tags":[]},"tz":"Europe/Berlin","now_local":"2026-11-11T12:00"}"#
        let t = MockTransport(json: json)
        let l = try await Node64.mock(t).monitor64.maintenance.list()
        #expect(l.items?.first?.status == .planned)
        #expect(l.items?.first?.startLocal == "2026-11-12T02:00")
        #expect(l.items?.first?.start != nil)
        #expect(l.hosts?.first?.name == "nas")
        #expect(l.tz == "Europe/Berlin")
        #expect(last(t).0 == "GET" && last(t).1 == "/monitor64/maintenance")

        let input = Node64.Monitor64MaintInput(title: "T", hosts: ["h1"], mode: .plan, start: "2026-11-12T02:00", end: "2026-11-12T03:00")
        let c = MockTransport(json: #"{"uid":"m2"}"#)
        #expect(try await Node64.mock(c).monitor64.maintenance.create(input) == "m2")
        #expect(last(c).0 == "POST" && last(c).1 == "/monitor64/maintenance")
        #expect(last(c).2 == .object(["title": .string("T"), "hosts": .array([.string("h1")]), "mode": .string("plan"), "start": .string("2026-11-12T02:00"), "end": .string("2026-11-12T03:00")]))
        let u = MockTransport(json: #"{"uid":"m2"}"#)
        _ = try await Node64.mock(u).monitor64.maintenance.update("m2", input)
        #expect(last(u).0 == "PUT" && last(u).1 == "/monitor64/maintenance/m2")
        let d = MockTransport(json: ok)
        try await Node64.mock(d).monitor64.maintenance.delete("m2")
        #expect(last(d).0 == "DELETE" && last(d).1 == "/monitor64/maintenance/m2")
        let e = MockTransport(json: ok)
        try await Node64.mock(e).monitor64.maintenance.end("m2")
        #expect(last(e).0 == "POST" && last(e).1 == "/monitor64/maintenance/m2/end")
    }
}
