import Foundation
import Testing
@testable import IPv64

@Suite("Healthchecks")
struct HealthchecksTests {
    static let token = "Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z"

    static let checkJSON = """
    {"token":"\(token)","name":"Backup NAS","type":"push","status":"up",
     "notify":{"on_down":true,"on_up":true,"integrations":[0]},
     "created_at":"2026-10-10T12:00:00+02:00","last_seen_at":"2026-10-10T12:00:00+02:00","last_alarm_at":null,
     "pings_total":1500,"failed_in_row":0,
     "push":{"url":"https://ipv64.net/health.php?token=\(token)","period_seconds":3600,"grace_seconds":600,"expected_by":"2026-10-10T12:00:00+02:00"},
     "check":null}
    """

    @Test("Healthcheck schema decodes")
    func decodeHealthcheck() throws {
        let check = try IPv64Coding.makeDecoder().decode(Healthcheck.self, from: Data(Self.checkJSON.utf8))
        #expect(check.token == Self.token)
        #expect(check.id == Self.token)
        #expect(check.type == .push)
        #expect(check.status == .up)
        #expect(check.notify?.integrations == [0])
        #expect(check.push?.periodSeconds == 3600)
        #expect(check.push?.expectedBy == Date(timeIntervalSince1970: 1_791_626_400))
        #expect(check.lastAlarmAt == nil)
        #expect(check.check == nil)
    }

    @Test("HealthcheckDetail schema decodes active check and recent events")
    func decodeDetail() throws {
        let json = """
        {"token":"\(Self.token)","name":"Web","type":"http","status":"down",
         "check":{"url":"https://example.com/","verify_tls":true,"prefer_ipv4":false,"interval_seconds":300,"retry_interval_seconds":60,"failures_before_alarm":3,"next_check_at":null},
         "recent":[{"id":1057264859,"time":"2026-10-10T12:00:00+02:00","status":"up","message":"Healthcheck is UP","latency_ms":23.4,"payload":{"a":1}}]}
        """
        let detail = try IPv64Coding.makeDecoder().decode(HealthcheckDetail.self, from: Data(json.utf8))
        #expect(detail.type == .http)
        #expect(detail.check?.verifyTLS == true)
        #expect(detail.check?.failuresBeforeAlarm == 3)
        #expect(detail.recent?.first?.latencyMs == 23.4)
        #expect(detail.recent?.first?.payload == .object(["a": .number(1)]))
    }

    @Test("Incident and HealthcheckStats schemas decode")
    func decodeIncidentAndStats() throws {
        let decoder = IPv64Coding.makeDecoder()
        let incident = try decoder.decode(Incident.self, from: Data("""
        {"id":991,"status":"closed","created_at":"2026-10-10T12:00:00+02:00","closed_at":null,
         "events":[{"time":"2026-10-10T12:00:00+02:00","kind":"down","message":"Healthcheck is DOWN"}]}
        """.utf8))
        #expect(incident.id == 991)
        #expect(incident.status == .closed)
        #expect(incident.events?.first?.kind == "down")

        let stats = try decoder.decode(HealthcheckStats.self, from: Data("""
        {"range":"24h","from":"2026-10-10T12:00:00+02:00","to":null,"measurements":288,"availability_percent":99.65,
         "latency_ms":{"avg":21.3,"min":12.0,"max":80.1},"bucket_seconds":900,
         "series":[{"time":"2026-10-10T12:00:00+02:00","measurements":3,"availability_percent":100,"latency_avg_ms":20.1,"latency_max_ms":null}]}
        """.utf8))
        #expect(stats.availabilityPercent == 99.65)
        #expect(stats.latencyMs?.max == 80.1)
        #expect(stats.series?.first?.latencyAvgMs == 20.1)
        #expect(stats.series?.first?.latencyMaxMs == nil)
    }

    @Test("list sends type and status filters")
    func list() async throws {
        let transport = MockTransport(json: #"{"data":[\#(Self.checkJSON)]}"#)
        let checks = try await IPv64.mock(transport).healthchecks.list(type: .push, status: .down)
        #expect(checks.count == 1)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.relativePath == "/healthchecks?type=push&status=down")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
    }

    @Test("create sends name and fields as JSON")
    func create() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":{"token":"\#(Self.token)","name":"Web"}}"#)
        let detail = try await IPv64.mock(transport).healthchecks.create(
            name: "Web",
            HealthcheckInput(type: .http, integrations: [0], url: "https://example.com/", verifyTLS: true, intervalSeconds: 300)
        )
        #expect(detail.token == Self.token)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/healthchecks")
        #expect(request.jsonBody == .object([
            "name": "Web", "type": "http", "integrations": .array([.number(0)]),
            "url": "https://example.com/", "verify_tls": .bool(true), "interval_seconds": .number(300),
        ]))
    }

    @Test("update sends only provided fields")
    func update() async throws {
        let transport = MockTransport(json: #"{"data":{"token":"\#(Self.token)"}}"#)
        _ = try await IPv64.mock(transport).healthchecks.update(
            Self.token, HealthcheckInput(intervalSeconds: 60, failuresBeforeAlarm: 2)
        )
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PATCH")
        #expect(request.relativePath == "/healthchecks/\(Self.token)")
        #expect(request.jsonBody == .object(["interval_seconds": .number(60), "failures_before_alarm": .number(2)]))
    }

    @Test("token path segment is percent-encoded")
    func encodedToken() async throws {
        let transport = MockTransport(json: #"{"data":{"token":"x"}}"#)
        _ = try await IPv64.mock(transport).healthchecks.get("a/b c")
        #expect(transport.lastRequest?.relativePath == "/healthchecks/a%2Fb%20c")
    }

    @Test("action endpoints use the right paths")
    func actions() async throws {
        let transport = MockTransport(json: #"{"data":{"token":"\#(Self.token)","sent":true}}"#)
        let api = IPv64.mock(transport).healthchecks
        _ = try await api.pause(Self.token)
        _ = try await api.resume(Self.token)
        _ = try await api.rotateToken(Self.token)
        let sent = try await api.sendTestNotification(Self.token)
        #expect(sent.sent == true)
        let paths = transport.requests.map { "\($0.httpMethod ?? "") \($0.relativePath)" }
        #expect(paths == [
            "POST /healthchecks/\(Self.token)/pause",
            "POST /healthchecks/\(Self.token)/resume",
            "POST /healthchecks/\(Self.token)/rotate-token",
            "POST /healthchecks/\(Self.token)/test-notification",
        ])
    }

    @Test("events returns a cursor page")
    func events() async throws {
        let transport = MockTransport(json: """
        {"data":[{"id":5,"time":"2026-10-10T12:00:00+02:00","status":"up","message":"ok","latency_ms":null,"payload":null}],
         "meta":{"limit":100,"has_more":true,"next_before":5,"next_after":null}}
        """)
        let since = Date(timeIntervalSince1970: 1_791_626_400)
        let page = try await IPv64.mock(transport).healthchecks.events(
            Self.token, limit: 100, before: 10, after: nil, since: since
        )
        #expect(page.items.first?.id == 5)
        #expect(page.meta?.hasMore == true)
        #expect(page.meta?.nextBefore == 5)
        #expect(page.meta?.nextAfter == nil)
        let path = try #require(transport.lastRequest?.relativePath)
        #expect(path.hasPrefix("/healthchecks/\(Self.token)/events?limit=100&before=10&since="))
    }

    @Test("incidents and stats send query parameters")
    func incidentsAndStats() async throws {
        let transport = MockTransport(json: #"{"data":[]}"#)
        let api = IPv64.mock(transport).healthchecks
        _ = try await api.incidents(Self.token, limit: 5)
        #expect(transport.lastRequest?.relativePath == "/healthchecks/\(Self.token)/incidents?limit=5")

        let statsTransport = MockTransport(json: #"{"data":{"range":"7d"}}"#)
        let stats = try await IPv64.mock(statsTransport).healthchecks.stats(Self.token, range: .sevenDays)
        #expect(stats.range == .sevenDays)
        #expect(statsTransport.lastRequest?.relativePath == "/healthchecks/\(Self.token)/stats?range=7d")
    }

    @Test("delete handles 204")
    func delete() async throws {
        let transport = MockTransport(status: 204)
        try await IPv64.mock(transport).healthchecks.delete(Self.token)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
        #expect(transport.lastRequest?.relativePath == "/healthchecks/\(Self.token)")
    }

    @Test("409 problem+json becomes IPv64Error.api")
    func conflict() async throws {
        let transport = MockTransport(status: 409, json: """
        {"type":"https://ipv64.net/api/v2/errors#healthcheck_in_use","title":"Conflict","status":409,
         "detail":"Used by failover.","code":"healthcheck_in_use"}
        """)
        do {
            try await IPv64.mock(transport).healthchecks.delete(Self.token)
            Issue.record("Expected an error")
        } catch let IPv64Error.api(problem) {
            #expect(problem.code == "healthcheck_in_use")
            #expect(problem.status == 409)
        }
    }
}
