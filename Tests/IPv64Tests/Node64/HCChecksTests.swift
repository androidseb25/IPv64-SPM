import Foundation
import Testing
@testable import IPv64

@Suite("Node64 healthchecks: checks")
struct Node64HCChecksTests {
    private let checkJSON = """
    {"token":"abcdef0123456789abcdef0123456789","name":"Web","type":"http","target":"https://example.com",
     "params":{"method":"GET","accept_status":"200-299"},"interval_seconds":60,"retry_interval_seconds":20,"retries":1,
     "connect_timeout_seconds":5,"timeout_seconds":10,"invert":false,"stabilize":3,"ip_mode":"auto","tags":["a"],
     "description":"d","paused":false,"parent":"p","critical":true,"execution":"both","policy":"majority",
     "locations":["nbg"],"notify_degraded":true,"notify_down":true,"notify_up":false,"channels":[1,2],"repeat_minutes":30,
     "revision":4,"created_at":"2026-10-01T10:00:00Z","updated_at":"2026-10-02T10:00:00Z","push_url":"https://x/push/t",
     "state":{"state":"degraded","since":"2026-10-02T10:00:00Z","last_latency_ms":12.5,"consecutive_fail":2,"consecutive_ok":0,"incident_id":7,"maintenance":false},
     "group":"Heimnetz","nodes":["n1"],"owner":"other","future":1}
    """

    @Test("Check decodes all fields")
    func decodeCheck() throws {
        let check = try IPv64Coding.makeDecoder().decode(Node64.Check.self, from: Data(checkJSON.utf8))
        #expect(check.id == "abcdef0123456789abcdef0123456789")
        #expect(check.type == .http)
        #expect(check.execution == .both)
        #expect(check.policy == .majority)
        #expect(check.owner == .other)
        #expect(check.ipMode == .auto)
        #expect(check.intervalSeconds == 60)
        #expect(check.params?["method"]?.stringValue == "GET")
        #expect(check.channels == [1, 2])
        #expect(check.notifyUp == false)
        #expect(check.pushURL == "https://x/push/t")
        #expect(check.state?.state == .degraded)
        #expect(check.state?.lastLatencyMS == 12.5)
        #expect(check.state?.incidentID == 7)
        #expect(check.group == "Heimnetz")
    }

    @Test("Measurement, event, incident and stats decode")
    func decodeHistory() throws {
        let decoder = IPv64Coding.makeDecoder()
        let measurement = try decoder.decode(Node64.CheckMeasurement.self, from: Data(#"{"seq":9,"time":"t","status":"up","latency_ms":3.5,"details":{"a":1},"dependent":false}"#.utf8))
        #expect(measurement.id == 9)
        #expect(measurement.status == .up)
        #expect(measurement.latencyMS == 3.5)
        let event = try decoder.decode(Node64.CheckEvent.self, from: Data(#"{"id":3,"event_id":"e","token":"t","kind":"down","from":"up","to":"down","duration_seconds":10,"incident_id":2,"silent":true}"#.utf8))
        #expect(event.id == 3)
        #expect(event.eventID == "e")
        #expect(event.durationSeconds == 10)
        #expect(event.from == "up")
        let incident = try decoder.decode(Node64.CheckIncident.self, from: Data(#"{"id":2,"token":"t","started_at":"s","ended_at":"e","open":false}"#.utf8))
        #expect(incident.startedAt == "s")
        #expect(incident.open == false)
        let stats = try decoder.decode(Node64.CheckStats.self, from: Data(#"{"range":"24h","count":2,"up_count":1,"up_percent":50,"avg_ms":1,"bucket_seconds":60,"series":[{"time":"t","count":1,"up_count":1,"avg_ms":2,"up_percent":100}]}"#.utf8))
        #expect(stats.upPercent == 50)
        #expect(stats.series?.first?.avgMS == 2)
    }

    @Test("Chart decodes series with null latency")
    func decodeChart() throws {
        let json = #"{"range":"24h","bucket":"raw","series":[{"source":"loc:nbg","label":"Nuremberg","points":[{"t":"2026-10-27T10:00:00Z","ms":null,"up":0}]}]}"#
        let chart = try IPv64Coding.makeDecoder().decode(Node64.CheckChart.self, from: Data(json.utf8))
        #expect(chart.bucket == .raw)
        #expect(chart.series?.first?.points?.first?.ms == nil)
        #expect(chart.series?.first?.points?.first?.t != nil)
    }

    @Test("list sends filters as query")
    func list() async throws {
        let transport = MockTransport(json: "[\(checkJSON)]")
        let checks = try await Node64.mock(transport).hc.checks.list(type: .http, state: .down, tag: "a b", query: "x")
        #expect(checks.count == 1)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.nodeRelativePath.hasPrefix("/checks?"))
        let query = request.url?.query ?? ""
        #expect(query.contains("type=http"))
        #expect(query.contains("state=down"))
        #expect(query.contains("tag=a%20b"))
        #expect(query.contains("q=x"))
    }

    @Test("create sends only the set fields as snake_case JSON")
    func create() async throws {
        let transport = MockTransport(status: 201, json: #"{"token":"t"}"#)
        let input = Node64.CheckInput(name: "Web", type: .http, target: "https://e.com", intervalSeconds: 30, execution: .online, locations: ["nbg"], notifyDown: true)
        let result = try await Node64.mock(transport).hc.checks.create(input)
        #expect(result["token"]?.stringValue == "t")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.nodeRelativePath == "/checks")
        let body = try #require(request.jsonBody)
        #expect(body["interval_seconds"]?.intValue == 30)
        #expect(body["execution"]?.stringValue == "online")
        #expect(body["notify_down"]?.boolValue == true)
        #expect(body["retries"] == nil)
    }

    @Test("get percent-encodes the token")
    func get() async throws {
        let transport = MockTransport(json: checkJSON)
        let check = try await Node64.mock(transport).hc.checks.get("a/b")
        #expect(check.name == "Web")
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/a%2Fb")
    }

    @Test("update always sends name, type and target and omits unset fields")
    func update() async throws {
        let transport = MockTransport(json: #"{"token":"tok"}"#)
        let input = Node64.CheckInput(name: "Web", type: .http, target: "https://e.com", description: "keep me")
        _ = try await Node64.mock(transport).hc.checks.update("tok", input)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.nodeRelativePath == "/checks/tok")
        #expect(request.jsonBody == .object([
            "name": .string("Web"),
            "type": .string("http"),
            "target": .string("https://e.com"),
            "description": .string("keep me"),
        ]))
    }

    @Test("A push check may omit the target")
    func pushWithoutTarget() async throws {
        let transport = MockTransport(json: #"{"token":"tok"}"#)
        _ = try await Node64.mock(transport).hc.checks.update("tok", Node64.CheckInput(name: "Backup", type: .push, target: nil))
        #expect(transport.lastRequest?.jsonBody == .object(["name": .string("Backup"), "type": .string("push")]))
    }

    @Test("pause, resume, clone return the check")
    func controls() async throws {
        let transport = MockTransport(json: checkJSON)
        let checks = Node64.mock(transport).hc.checks
        _ = try await checks.pause("t")
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/t/pause")
        _ = try await checks.resume("t")
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/t/resume")
        let clone = try await checks.clone("t")
        #expect(clone.name == "Web")
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/t/clone")
        #expect(transport.lastRequest?.httpMethod == "POST")
    }

    @Test("delete (204) and run (202) return without content")
    func noContent() async throws {
        let deleted = MockTransport(status: 204)
        try await Node64.mock(deleted).hc.checks.delete("t")
        #expect(deleted.lastRequest?.httpMethod == "DELETE")
        let run = MockTransport(status: 202)
        try await Node64.mock(run).hc.checks.run("t")
        #expect(run.lastRequest?.nodeRelativePath == "/checks/t/run")
    }

    @Test("History endpoints build their queries")
    func history() async throws {
        let transport = MockTransport(json: "[]")
        let checks = Node64.mock(transport).hc.checks
        _ = try await checks.measurements("t", limit: 5, before: 10)
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/t/measurements?limit=5&before=10")
        _ = try await checks.events("t", limit: 2)
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/t/events?limit=2")
        _ = try await checks.incidents("t", limit: 3)
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/t/incidents?limit=3")
        let node = Node64.mock(transport)
        _ = try await node.hc.events(before: 4)
        #expect(transport.lastRequest?.nodeRelativePath == "/events?before=4")
        _ = try await node.hc.incidents()
        #expect(transport.lastRequest?.nodeRelativePath == "/incidents")
    }

    @Test("stats and chart send range")
    func statsChart() async throws {
        let transport = MockTransport(json: "{}")
        let checks = Node64.mock(transport).hc.checks
        _ = try await checks.stats("t", range: .last7Days)
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/t/stats?range=7d")
        _ = try await checks.chart("t", range: .last6Hours)
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/t/chart?range=6h")
    }

    @Test("bulk sends action, tokens and tag")
    func bulk() async throws {
        let transport = MockTransport(json: #"{"done":1,"failed":[{"token":"b","error":"nope"}]}"#)
        let result = try await Node64.mock(transport).hc.checks.bulk(.tag, tokens: ["a", "b"], tag: "x")
        #expect(result.done == 1)
        #expect(result.failed?.first?.error == "nope")
        let body = try #require(transport.lastRequest?.jsonBody)
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/bulk")
        #expect(body["action"]?.stringValue == "tag")
        #expect(body["tag"]?.stringValue == "x")
    }

    @Test("onlineTest merges the check fields with the token")
    func onlineTest() async throws {
        let transport = MockTransport(json: #"{"status":"failed","error":"e","results":[{"location":"nbg","ok":false,"message":"m"}]}"#)
        let result = try await Node64.mock(transport).hc.checks.onlineTest(Node64.CheckInput(name: "n", type: .http, target: "t"), token: "tok")
        #expect(result.status == .failed)
        #expect(result.results?.first?.location == "nbg")
        let body = try #require(transport.lastRequest?.jsonBody)
        #expect(transport.lastRequest?.nodeRelativePath == "/checks/online-test")
        #expect(body["name"]?.stringValue == "n")
        #expect(body["token"]?.stringValue == "tok")
    }

    @Test("Error documents become Node64Error.api")
    func errorDocument() async throws {
        let transport = MockTransport(status: 404, json: #"{"error":"check not found"}"#)
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).hc.checks.get("x")
        }
        guard case .api(let document) = error else {
            Issue.record("Expected an API error")
            return
        }
        #expect(document.status == 404)
        #expect(document.error == "check not found")
    }
}

@Suite("Node64 healthchecks: online checks and maintenance")
struct Node64HCOnlineAndMaintenanceTests {
    @Test("Online-check actions use the action path segment")
    func onlineAction() async throws {
        let transport = MockTransport(status: 202)
        let online = Node64.mock(transport).hc.onlineChecks
        try await online.perform("t", action: .run)
        #expect(transport.lastRequest?.nodeRelativePath == "/online-checks/t/run")
        try await online.pause("t")
        #expect(transport.lastRequest?.nodeRelativePath == "/online-checks/t/pause")
        try await online.resume("t")
        #expect(transport.lastRequest?.nodeRelativePath == "/online-checks/t/resume")
        #expect(transport.lastRequest?.httpMethod == "POST")
    }

    @Test("Online-check CRUD")
    func onlineCrud() async throws {
        let transport = MockTransport(json: #"{"token":"t","name":"n"}"#)
        let online = Node64.mock(transport).hc.onlineChecks
        let created = try await online.create(Node64.CheckInput(name: "n", type: .http, target: "x"))
        #expect(created.token == "t")
        #expect(transport.lastRequest?.nodeRelativePath == "/online-checks")
        _ = try await online.get("t")
        _ = try await online.update("t", Node64.CheckInput(name: "n", type: .http, target: "x"))
        #expect(transport.lastRequest?.httpMethod == "PUT")
        let listing = MockTransport(json: #"[{"token":"t"}]"#)
        #expect(try await Node64.mock(listing).hc.onlineChecks.list().count == 1)
        #expect(listing.lastRequest?.nodeRelativePath == "/online-checks")
        let deleted = MockTransport(status: 204)
        try await Node64.mock(deleted).hc.onlineChecks.delete("t")
        #expect(deleted.lastRequest?.nodeRelativePath == "/online-checks/t")
    }

    @Test("Maintenance decodes and encodes dates")
    func maintenance() async throws {
        let json = #"[{"id":1,"name":"M","start_at":"s","end_at":"e","repeat":"weekly","tokens":["a"],"active":true,"created_at":"2026-10-27T10:00:00Z","remote_id":5,"revision":2}]"#
        let transport = MockTransport(json: json)
        let maintenance = Node64.mock(transport).hc.maintenance
        let windows = try await maintenance.list()
        #expect(windows.first?.repeat == .weekly)
        #expect(windows.first?.remoteID == 5)
        #expect(windows.first?.createdAt != nil)

        let input = Node64.MaintenanceInput(name: "M", startAt: Date(timeIntervalSince1970: 0), endAt: Date(timeIntervalSince1970: 3600), repeat: .daily)
        _ = try await maintenance.create(input)
        #expect(transport.lastRequest?.httpMethod == "POST")
        let body = try #require(transport.lastRequest?.jsonBody)
        #expect(body["repeat"]?.stringValue == "daily")
        #expect(body["start_at"]?.stringValue?.hasPrefix("1970-01-01") == true)
        _ = try await maintenance.update(3, input)
        #expect(transport.lastRequest?.nodeRelativePath == "/maintenance/3")
        #expect(transport.lastRequest?.httpMethod == "PUT")
    }

    @Test("Maintenance delete answers 204")
    func maintenanceDelete() async throws {
        let transport = MockTransport(status: 204)
        try await Node64.mock(transport).hc.maintenance.delete(8)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
        #expect(transport.lastRequest?.nodeRelativePath == "/maintenance/8")
    }
}
