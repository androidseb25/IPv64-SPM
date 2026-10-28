import Foundation
import Testing
@testable import IPv64

@Suite("HC2")
struct HC2Tests {
    static let checkJSON = """
    {"name":"Backup NAS","type":"http","target":"https://example.com/","params":{"method":"GET","accept_status":"200-299","json_rules":[{"path":"a.b","op":"not_exists"}],"record_type":"AAAA"},
     "interval_seconds":60,"retry_interval_seconds":20,"retries":1,"connect_timeout_seconds":5,"timeout_seconds":10.5,"invert":false,"stabilize":3,
     "ip_mode":"auto","tags":["a"],"group":"Heimnetz","execution":"online","nodes":[{"node_id":"n1","name":"Home"}],"locations":["nbg","fsn"],"policy":"all",
     "notify_down":true,"channels":[1,2],"repeat_minutes":0,"token":"Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z","revision":4,
     "created_at":"2026-10-10T12:00:00+02:00","updated_at":null,
     "state":{"state":"up","since":"2026-10-10T12:00:00+02:00","last_status":"up","last_latency_ms":12.5},
     "push":{"url":"https://ipv64.net/p","hub_url":"h","node_path":"p"}}
    """

    @Test("HC2CheckDetail flattens Hc2Check and detail fields")
    func checkDetailDecode() async throws {
        let json = Self.checkJSON.dropLast()
            + #","sources":[{"source":"loc:nbg","label":"Nürnberg","state":"up","consecutive_ok":5}],"availability_percent":{"24h":100,"30d":99.5,"1y":99.9}}"#
        let transport = MockTransport(json: #"{"data":\#(json)}"#)
        let check = try await IPv64.mock(transport).hc2.checks.get("Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z")

        #expect(check.id == "Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z")
        #expect(check.type == .http)
        #expect(check.params?.jsonRules?.first?.op == .notExists)
        #expect(check.params?.recordType == .aaaa)
        #expect(check.nodes?.first?.nodeID == "n1")
        #expect(check.locations == [.nuremberg, .falkenstein])
        #expect(check.timeoutSeconds == 10.5)
        #expect(check.updatedAt == nil)
        #expect(check.state?.lastLatencyMS == 12.5)
        #expect(check.sources?.first?.consecutiveOK == 5)
        #expect(check.availabilityPercent?.last30Days == 99.5)
        #expect(transport.lastRequest?.relativePath == "/hc2/checks/Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z")
    }

    @Test("HC2Check decodes alone")
    func checkDecode() throws {
        let check = try IPv64Coding.makeDecoder().decode(HC2Check.self, from: Data(Self.checkJSON.utf8))
        #expect(check.push?.hubURL == "h")
        #expect(check.channels == [1, 2])
    }

    @Test("Check nodes decode from objects and from plain ID strings")
    func nodeReferences() throws {
        let json = #"{"token":"t","nodes":[{"node_id":"n1","name":"Home"},"n2"]}"#
        let check = try IPv64Coding.makeDecoder().decode(HC2Check.self, from: Data(json.utf8))
        let nodes = try #require(check.nodes)
        #expect(nodes.map(\.nodeID) == ["n1", "n2"])
        #expect(nodes.map(\.name) == ["Home", nil])
    }

    @Test("HC2CheckInput encodes only provided fields with snake_case keys")
    func checkInputEncoding() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":{"token":"t"}}"#)
        let input = HC2CheckInput(
            name: "NAS", type: .keyword, target: "https://x.test", params: .init(keyword: "ok", keywordAbsent: false),
            intervalSeconds: 60, execution: .both, nodeID: "n", nodes: ["n"], locations: [.nuremberg],
            notifyDown: true
        )
        _ = try await IPv64.mock(transport).hc2.checks.create(input)

        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(request.jsonBody == [
            "name": "NAS", "type": "keyword", "target": "https://x.test",
            "params": ["keyword": "ok", "keyword_absent": false],
            "interval_seconds": 60, "execution": "both", "node_id": "n", "nodes": ["n"],
            "locations": ["nbg"], "notify_down": true,
        ])
    }

    @Test("PATCH check sends only changed fields")
    func checkUpdate() async throws {
        let transport = MockTransport(json: #"{"data":{"token":"t"}}"#)
        _ = try await IPv64.mock(transport).hc2.checks.update("t", HC2CheckInput(name: "New", type: .http))
        #expect(transport.lastRequest?.httpMethod == "PATCH")
        #expect(transport.lastRequest?.jsonBody == ["name": "New", "type": "http"])
    }

    @Test("List filters are sent as query items")
    func listQuery() async throws {
        let transport = MockTransport(json: #"{"data":[]}"#)
        _ = try await IPv64.mock(transport).hc2.checks.list(state: .down, execution: .local, nodeID: "n1", query: "a b")
        #expect(transport.lastRequest?.relativePath == "/hc2/checks?state=down&execution=local&node_id=n1&q=a%20b")
    }

    @Test("Event pagination sends before/after and decodes HC2PageMeta")
    func eventsPagination() async throws {
        let transport = MockTransport(json: """
        {"data":[{"id":41,"event_id":"e","token":"t","kind":"degraded_end","time":"2026-10-10T12:00:00+02:00","silent":true,"incident_id":3}],
         "meta":{"limit":1,"has_more":true,"next_before":41,"next_after":41}}
        """)
        let client = IPv64.mock(transport)
        let page = try await client.hc2.checks.events("tok", limit: 1, before: 50, since: Date(timeIntervalSince1970: 1_791_626_400))
        #expect(page.items.first?.kind == .degradedEnd)
        #expect(page.meta?.hasMore == true)
        #expect(page.meta?.nextBefore == 41)
        #expect(transport.lastRequest?.relativePath.hasPrefix("/hc2/checks/tok/events?limit=1&before=50&since=") == true)

        _ = try await client.hc2.events(after: 41)
        #expect(transport.lastRequest?.relativePath == "/hc2/events?after=41")
    }

    @Test("Incidents encode open as true/false")
    func incidents() async throws {
        let transport = MockTransport(json: """
        {"data":[{"id":1,"token":"t","name":"n","status":"open","started_at":"2026-10-10T12:00:00+02:00","ended_at":null,"sources":["loc:nbg"]}]}
        """)
        let client = IPv64.mock(transport)
        let list = try await client.hc2.incidents.list(limit: 10, open: true)
        #expect(list.first?.status == .open)
        #expect(transport.lastRequest?.relativePath == "/hc2/incidents?limit=10&open=true")
        _ = try await client.hc2.incidents.list(check: "tok", limit: 5)
        #expect(transport.lastRequest?.relativePath == "/hc2/checks/tok/incidents?limit=5")
    }

    @Test("Stats, measurements, testrun and run decode")
    func statsAndMore() async throws {
        let client1 = IPv64.mock(MockTransport(json: """
        {"data":{"range":"24h","bucket":"hour","measurements":10,"availability_percent":99.5,
        "sources":[{"source":"loc:nbg","label":"N","measurements":5,"availability_percent":100,"latency_ms":{"min":1,"avg":2.5,"max":4}}],
        "series":[{"time":"2026-10-10T12:00:00+02:00","source":"loc:nbg","measurements":5,"availability_percent":100,"latency_avg_ms":2,"latency_max_ms":3}]}}
        """))
        let stats = try await client1.hc2.checks.stats("t", range: .last24Hours)
        #expect(stats.sources?.first?.latencyMS?.avg == 2.5)
        #expect(stats.series?.first?.latencyMaxMS == 3)

        let measurements = try await IPv64.mock(MockTransport(json: """
        {"data":[{"time":"2026-10-10T12:00:00+02:00","source":"loc:nbg","status":"down","latency_ms":3,"family":"ipv4","details":{"a":1}}]}
        """)).hc2.checks.measurements("t", limit: 5000)
        #expect(measurements.first?.status == .down)
        #expect(measurements.first?.details?["a"]?.intValue == 1)

        let testrun = try await IPv64.mock(MockTransport(json: """
        {"data":{"id":7,"status":"running","target":"local","applied":false,"results":[{"source":"node:x","ok":true,"message":"m"}]}}
        """)).hc2.checks.testrun(7)
        #expect(testrun.id == 7)
        #expect(testrun.results?.first?.ok == true)

        let run = try await IPv64.mock(MockTransport(status: 202, json: #"{"data":{"queued":true,"command_id":9,"node_id":"n","detail":"d"}}"#)).hc2.checks.run("t")
        #expect(run.commandID == 9)
    }

    @Test("Move sends a test-run body")
    func move() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":{"id":7,"status":"pending"}}"#)
        let run = try await IPv64.mock(transport).hc2.checks.move("t", execution: .local, nodeID: "n1")
        #expect(run.status == .pending)
        #expect(transport.lastRequest?.relativePath == "/hc2/checks/t/move")
        #expect(transport.lastRequest?.jsonBody == ["execution": "local", "node_id": "n1"])
    }

    @Test("Pause and delete")
    func pauseAndDelete() async throws {
        let transport = MockTransport(json: #"{"data":{"token":"t","paused":true}}"#)
        let paused = try await IPv64.mock(transport).hc2.checks.pause("t")
        #expect(paused.paused == true)
        #expect(transport.lastRequest?.relativePath == "/hc2/checks/t/pause")

        let deleteTransport = MockTransport(status: 204, body: Data())
        try await IPv64.mock(deleteTransport).hc2.checks.delete("t")
        #expect(deleteTransport.lastRequest?.httpMethod == "DELETE")
    }

    @Test("Account and settings")
    func accountAndSettings() async throws {
        let account = try await IPv64.mock(MockTransport(json: """
        {"data":{"plan":"pro","online_measuring_points":{"used":2,"limit":null},"checks_per_day":{"used":1,"limit":100},"locations_per_check":2,"sms_per_day":5,
        "locations":[{"code":"nbg","name":"Nürnberg"}],"nodes":{"total":2,"online":1},"checks":7}}
        """)).hc2.account()
        #expect(account.onlineMeasuringPoints?.limit == nil)
        #expect(account.nodes?.online == 1)

        let transport = MockTransport(json: #"{"data":{"notify.quiet_from":"22:00"}}"#)
        let settings = try await IPv64.mock(transport).hc2.updateSettings(.init(quietEnabled: true, quietFrom: "22:00", ratePerHour: 0))
        #expect(settings["notify.quiet_from"] == "22:00")
        #expect(transport.lastRequest?.jsonBody == ["notify.quiet_enabled": true, "notify.quiet_from": "22:00", "notify.rate_per_hour": 0])
    }

    @Test("Channels: decode, create, send, test, 204 delete")
    func channels() async throws {
        let channelJSON = """
        {"id":7,"type":"ntfy","type_label":"ntfy","name":"Phone","config":{"topic":"x","n":1},"secrets_set":["token"],"enabled":true,"default":false,
        "verified":true,"lang":"de","notify_down":true,"notify_up":false,"execution":"server","last_used":null,"revision":1,"sendable_via_api":false}
        """
        let transport = MockTransport(status: 201, json: #"{"data":\#(channelJSON)}"#)
        let channel = try await IPv64.mock(transport).hc2.channels.create(
            HC2ChannelInput(name: "Phone", type: .ntfy, config: ["topic": "x"], default: false, lang: .de)
        )
        #expect(channel.id == 7)
        #expect(channel.default == false)
        #expect(channel.config?["n"]?.intValue == 1)
        #expect(channel.secretsSet == ["token"])
        #expect(transport.lastRequest?.jsonBody == ["name": "Phone", "type": "ntfy", "config": ["topic": "x"], "default": false, "lang": "de"])

        let send = MockTransport(json: #"{"data":{"sent":true,"duplicate":false,"sms_left":null}}"#)
        let result = try await IPv64.mock(send).hc2.channels.send(7, subject: "S", text: "T", eventID: "e1")
        #expect(result.sent == true)
        #expect(send.lastRequest?.relativePath == "/hc2/channels/7/send")
        #expect(send.lastRequest?.jsonBody == ["subject": "S", "text": "T", "event_id": "e1"])

        let test = try await IPv64.mock(MockTransport(json: #"{"data":{"sent":false,"queued_at_node":true}}"#)).hc2.channels.sendTest(7)
        #expect(test.queuedAtNode == true)

        let types = try await IPv64.mock(MockTransport(json: """
        {"data":[{"type":"smtp","label":"SMTP","needs_verification":false,"fields":[{"key":"host","label":"Host","kind":"text","required":true,"secret":false,"options":["a"],"default":"x"}]}]}
        """)).hc2.channels.types()
        #expect(types.first?.fields?.first?.kind == .init(rawValue: "text"))

        let del = MockTransport(status: 204, body: Data())
        try await IPv64.mock(del).hc2.channels.delete(7)
        #expect(del.lastRequest?.relativePath == "/hc2/channels/7")
    }

    @Test("Channels: send verification code")
    func sendVerificationCode() async throws {
        let transport = MockTransport(json: #"{"data":{"sent":true}}"#)
        let result = try await IPv64.mock(transport).hc2.channels.sendVerificationCode(7)
        #expect(result == ["sent": true])
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/hc2/channels/7/verify/send")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(request.httpBody == nil)

        let verified = MockTransport(json: #"{"verified":true}"#)
        #expect(try await IPv64.mock(verified).hc2.channels.sendVerificationCode(7)["verified"] == true)

        let empty = MockTransport(status: 200, body: Data())
        #expect(try await IPv64.mock(empty).hc2.channels.sendVerificationCode(7) == .null)

        let limited = MockTransport(status: 429, json: """
        {"type":"about:blank","title":"Too Many Requests","status":429,"code":"rate_limited","detail":"slow","retry_after":600}
        """)
        do {
            _ = try await IPv64.mock(limited).hc2.channels.sendVerificationCode(7)
            Issue.record("expected an error")
        } catch let IPv64Error.api(problem) {
            #expect(problem.status == 429)
            #expect(problem.retryAfter == 600)
        }
    }

    @Test("Channels: verify with code")
    func verifyChannel() async throws {
        let transport = MockTransport(json: #"{"data":{"verified":true}}"#)
        let result = try await IPv64.mock(transport).hc2.channels.verify(7, code: "123456")
        #expect(result == ["verified": true])
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/hc2/channels/7/verify")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
        #expect(request.jsonBody == ["code": "123456"])

        let plain = MockTransport(json: #"{"verified":true}"#)
        #expect(try await IPv64.mock(plain).hc2.channels.verify(7, code: "123456")["verified"] == true)

        let empty = MockTransport(status: 200, body: Data())
        #expect(try await IPv64.mock(empty).hc2.channels.verify(7, code: "123456") == .null)
    }

    @Test("Channels: wrong code becomes invalid_code")
    func verifyInvalidCode() async throws {
        let transport = MockTransport(status: 422, json: """
        {"type":"about:blank","title":"Unprocessable Entity","status":422,"code":"invalid_code","detail":"Wrong or expired code"}
        """)
        do {
            _ = try await IPv64.mock(transport).hc2.channels.verify(7, code: "000000")
            Issue.record("expected an error")
        } catch let IPv64Error.api(problem) {
            #expect(problem.code == "invalid_code")
            #expect(problem.status == 422)
        }
    }

    @Test("Maintenance windows encode dates")
    func maintenance() async throws {
        let transport = MockTransport(status: 201, json: """
        {"data":{"id":3,"name":"M","start_at":"2026-10-10T12:00:00+02:00","end_at":"2026-10-10T13:00:00+02:00","repeat":"weekly","repeat_until":null,"tokens":[],"active":true,"node_id":"","revision":1}}
        """)
        let start = Date(timeIntervalSince1970: 1_791_626_400)
        let m = try await IPv64.mock(transport).hc2.maintenances.create(
            HC2MaintenanceInput(name: "M", startAt: start, endAt: start.addingTimeInterval(3600), repeat: .weekly)
        )
        #expect(m.repeat == .weekly)
        #expect(m.startAt == start)
        let body = try #require(transport.lastRequest?.jsonBody)
        #expect(body["name"]?.stringValue == "M")
        #expect(body["repeat"]?.stringValue == "weekly")
        #expect(body["start_at"] == "2026-10-10T10:00:00Z")
        #expect(body["end_at"] == "2026-10-10T11:00:00Z")
        #expect(transport.lastRequest?.relativePath == "/hc2/maintenance")

        let update = MockTransport(json: #"{"data":{"id":3}}"#)
        _ = try await IPv64.mock(update).hc2.maintenances.update(3, HC2MaintenanceInput(name: "X"))
        #expect(update.lastRequest?.relativePath == "/hc2/maintenance/3")
        #expect(update.lastRequest?.jsonBody == ["name": "X"])
    }

    @Test("Problem responses become IPv64Error.api")
    func problem() async throws {
        let transport = MockTransport(status: 409, json: """
        {"type":"about:blank","title":"Conflict","status":409,"code":"move_requires_test","detail":"use move"}
        """)
        do {
            _ = try await IPv64.mock(transport).hc2.checks.update("t", HC2CheckInput(name: "n", type: .http))
            Issue.record("expected an error")
        } catch let IPv64Error.api(problem) {
            #expect(problem.code == "move_requires_test")
        }
    }
}
