import Foundation
import Testing
@testable import IPv64

@Suite("Node64 DynDNS")
struct Node64DynDNSTests {
    static let targetJSON = """
    {"id":3,"domain":"home.ipv64.net","host":"nas","fqdn":"nas.home.ipv64.net","record_id":42,"token_kind":"record",
     "token_hint":"ab12","mode4":"auto","fixed4":"","mode6":"suffix","suffix6":"::1a2b","iface":"","enabled":true,
     "paused":"","status":"ok","last_ipv4":"203.0.113.10","last_ipv6":"2001:db8::1","last_prefix":"2001:db8::/64",
     "last_ok_at":"2026-10-27T08:00:00Z","last_error":"","last_error_at":null,"dns_state":"redirected"}
    """

    @Test("DynDNSTarget decodes")
    func decodeTarget() throws {
        let target = try IPv64Coding.makeDecoder().decode(Node64.DynDNSTarget.self, from: Data(Self.targetJSON.utf8))
        #expect(target.id == 3)
        #expect(target.recordID == 42)
        #expect(target.mode6 == .suffix)
        #expect(target.status == .ok)
        #expect(target.dnsState == .redirected)
        #expect(target.lastOKAt == Date(timeIntervalSince1970: 1_793_088_000))
        #expect(target.lastErrorAt == nil)
    }

    @Test("Account names, settings and status decode")
    func decodeOthers() throws {
        let name = try IPv64Coding.makeDecoder().decode(Node64.DynDNSAccountName.self, from: Data("""
        {"key":"home.ipv64.net|nas","domain":"home.ipv64.net","host":"nas","fqdn":"nas.home.ipv64.net","kind":"dyndns",
         "a":["203.0.113.10"],"aaaa":[],"suffix_of":"::1","default_mode4":"auto","default_mode6":"host","exists":false}
        """.utf8))
        #expect(name.id == "home.ipv64.net|nas")
        #expect(name.kind == .dyndns)
        #expect(name.defaultMode6 == .host)

        let settings = try IPv64Coding.makeDecoder().decode(Node64.DynDNSSettings.self, from: Data("""
        {"interval_minutes":5,"source4":"","keep_checks_days":30,"keep_updates_days":0,"notify_ip":true,"notify_fail":false,"notify_limit":true}
        """.utf8))
        #expect(settings.intervalMinutes == 5)
        #expect(settings.keepUpdatesDays == 0)

        let status = try IPv64Coding.makeDecoder().decode(Node64.DynDNSStatus.self, from: Data("""
        {"ipv4":"203.0.113.10","connection":{"suspect":"cgnat"},"limit":{"used":3,"limit":0,"own_24h":2}}
        """.utf8))
        #expect(status.connection?.suspect == "cgnat")
        #expect(status.limit?.own24h == 2)
    }

    @Test("Creating a target sends the input as JSON")
    func createTarget() async throws {
        let transport = MockTransport(status: 201, json: Self.targetJSON)
        let input = Node64.DynDNSTargetInput(
            domain: "home.ipv64.net", host: "nas", token: "tok", mode4: .auto, mode6: .suffix, suffix6: "::1a2b"
        )

        let target = try await Node64.mock(transport).dyndns.targets.create(input)

        #expect(target.id == 3)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.nodeRelativePath == "/dyndns/targets")
        #expect(request.jsonBody == .object([
            "domain": .string("home.ipv64.net"), "host": .string("nas"), "token": .string("tok"),
            "mode4": .string("auto"), "mode6": .string("suffix"), "suffix6": .string("::1a2b"),
        ]))
    }

    @Test("History sends its query items")
    func history() async throws {
        let transport = MockTransport(json: #"{"items":[],"truncated":false}"#)

        _ = try await Node64.mock(transport).dyndns.history(type: .checks, family: .v6, days: 0)

        let path = try #require(transport.lastRequest).nodeRelativePath
        #expect(path.hasPrefix("/dyndns/history?"))
        #expect(path.contains("type=checks") && path.contains("family=6") && path.contains("days=0"))
    }

    @Test("Immediate update and token refresh use their paths")
    func updateNow() async throws {
        let transport = MockTransport(json: #"{"result":"sent","target":\#(Self.targetJSON)}"#)
        let result = try await Node64.mock(transport).dyndns.targets.updateNow(3)
        #expect(result.result == .sent)
        #expect(result.target?.id == 3)
        #expect(transport.lastRequest?.nodeRelativePath == "/dyndns/targets/3/update")

        let refresh = MockTransport(json: Self.targetJSON)
        _ = try await Node64.mock(refresh).dyndns.targets.refreshToken(3)
        #expect(refresh.lastRequest?.nodeRelativePath == "/dyndns/targets/3/token")
    }

    @Test("check() distinguishes finished and running rounds")
    func check() async throws {
        let done = try await Node64.mock(MockTransport(json: #"{"ipv4":"203.0.113.10"}"#)).dyndns.check()
        guard case .completed(let status) = done else {
            Issue.record("Expected completed")
            return
        }
        #expect(status.ipv4 == "203.0.113.10")

        let running = try await Node64.mock(MockTransport(status: 202, json: #"{"status":"running"}"#)).dyndns.check()
        #expect(running == .running)
    }

    @Test("createFromAccount sends an array body")
    func fromAccount() async throws {
        let transport = MockTransport(status: 201, json: #"{"created":[],"skipped":[]}"#)

        try await Node64.mock(transport).dyndns.targets.createFromAccount([
            .init(key: "home.ipv64.net|nas", mode4: .auto), .init(key: "home.ipv64.net|"),
        ])

        #expect(transport.lastRequest?.nodeRelativePath == "/dyndns/targets/from-account")
        #expect(transport.lastRequest?.jsonBody == .array([
            .object(["key": .string("home.ipv64.net|nas"), "mode4": .string("auto")]),
            .object(["key": .string("home.ipv64.net|")]),
        ]))
    }

    @Test("Deleting a target accepts 204")
    func deleteTarget() async throws {
        let transport = MockTransport(status: 204)
        try await Node64.mock(transport).dyndns.targets.delete(3)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
        #expect(transport.lastRequest?.nodeRelativePath == "/dyndns/targets/3")
    }

    @Test("Updating settings sends snake_case keys")
    func settings() async throws {
        let transport = MockTransport(json: #"{"interval_minutes":10}"#)
        let result = try await Node64.mock(transport).dyndns.updateSettings(.init(intervalMinutes: 10, notifyIP: true))
        #expect(result.intervalMinutes == 10)
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.jsonBody == .object(["interval_minutes": .number(10), "notify_ip": .bool(true)]))
    }

    @Test("Errors become Node64Error.api")
    func apiError() async throws {
        let transport = MockTransport(status: 409, json: #"{"error":"Domain + Host gibt es schon","code":"exists"}"#)
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).dyndns.targets.get(3)
        }
        guard case .api(let document) = error else {
            Issue.record("Expected an API error")
            return
        }
        #expect(document.status == 409)
    }
}
