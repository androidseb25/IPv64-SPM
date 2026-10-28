import Foundation
import Testing
@testable import IPv64

@Suite("Failover")
struct FailoverTests {
    static let policyJSON = """
    {"id":"QTl4iPM2swRaxWdz","name":"Webserver","status":"active","manual":false,"mode":"auto_failover",
     "fallback_requires_all":false,"linking":"or","notifications_enabled":true,"integrations":[0],"monitors_down":0,
     "last_check_at":"2026-10-10T12:00:00+02:00",
     "monitors":[{"healthcheck":"Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z","name":"Webserver HTTP","negate":false,"healthcheck_status":"up"}],
     "rules":[{"record":"tok","fqdn":"www.beispiel.ipv64.de","record_type":"A","state":"standby",
               "target":{"kind":"ip","ip":"198.51.100.5"}},
              {"record":"tok2","fqdn":null,"record_type":"A","state":"failed_over",
               "target":{"kind":"offline_page","offline_page":"default"}}]}
    """

    @Test("FailoverPolicy schema decodes")
    func decode() throws {
        let policy = try IPv64Coding.makeDecoder().decode(FailoverPolicy.self, from: Data(Self.policyJSON.utf8))
        #expect(policy.id == "QTl4iPM2swRaxWdz")
        #expect(policy.status == .active)
        #expect(policy.mode == .autoFailover)
        #expect(policy.linking == .or)
        #expect(policy.monitors?.first?.healthcheckStatus == .up)
        #expect(policy.rules?.first?.recordType == .a)
        #expect(policy.rules?.first?.target?.kind == .ip)
        #expect(policy.rules?.first?.target?.ip == "198.51.100.5")
        #expect(policy.rules?.last?.state == .failedOver)
        #expect(policy.rules?.last?.target?.offlinePage == "default")
        #expect(policy.rules?.last?.fqdn == nil)
    }

    @Test("create sends only provided fields")
    func create() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.policyJSON)}"#)
        let policy = try await IPv64.mock(transport).failover.create(
            FailoverPolicyInput(name: "Webserver", mode: .autoFailoverAndFallback)
        )
        #expect(policy.name == "Webserver")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/failover/policies")
        #expect(request.jsonBody == .object(["name": "Webserver", "mode": "auto_failover_and_fallback"]))
    }

    @Test("update, list, get and delete")
    func crud() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.policyJSON)}"#)
        let api = IPv64.mock(transport).failover
        _ = try await api.update("12", FailoverPolicyInput(notificationsEnabled: false))
        _ = try await api.get("12")
        #expect(transport.requests[0].httpMethod == "PATCH")
        #expect(transport.requests[0].relativePath == "/failover/policies/12")
        #expect(transport.requests[0].jsonBody == .object(["notifications_enabled": .bool(false)]))
        #expect(transport.requests[1].relativePath == "/failover/policies/12")

        let listTransport = MockTransport(json: #"{"data":[\#(Self.policyJSON)]}"#)
        #expect(try await IPv64.mock(listTransport).failover.list().count == 1)
        #expect(listTransport.lastRequest?.relativePath == "/failover/policies")

        let deleteTransport = MockTransport(status: 204)
        try await IPv64.mock(deleteTransport).failover.delete("12")
        #expect(deleteTransport.lastRequest?.httpMethod == "DELETE")
    }

    @Test("actions use the right paths")
    func actions() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":\#(Self.policyJSON)}"#)
        let api = IPv64.mock(transport).failover
        _ = try await api.failOver("12")
        _ = try await api.fallBack("12")
        let okTransport = MockTransport(json: #"{"data":\#(Self.policyJSON)}"#)
        _ = try await IPv64.mock(okTransport).failover.pause("12")
        _ = try await IPv64.mock(okTransport).failover.resume("12")
        #expect(transport.requests.map(\.relativePath) == ["/failover/policies/12/failover", "/failover/policies/12/fallback"])
        #expect(okTransport.requests.map(\.relativePath) == ["/failover/policies/12/pause", "/failover/policies/12/resume"])
    }

    @Test("monitors and rules")
    func monitorsAndRules() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.policyJSON)}"#)
        let api = IPv64.mock(transport).failover
        _ = try await api.addMonitor(policy: "12", healthcheck: "tok", negate: true)
        #expect(transport.lastRequest?.relativePath == "/failover/policies/12/monitors")
        #expect(transport.lastRequest?.jsonBody == .object(["healthcheck": "tok", "negate": .bool(true)]))

        _ = try await api.addRule(policy: "12", record: "4711", targetIP: "198.51.100.5")
        #expect(transport.lastRequest?.relativePath == "/failover/policies/12/rules")
        #expect(transport.lastRequest?.jsonBody == .object(["record": "4711", "target_ip": "198.51.100.5"]))

        _ = try await api.addRule(policy: "12", record: "4711", offlinePage: "default")
        #expect(transport.lastRequest?.jsonBody == .object(["record": "4711", "offline_page": "default"]))

        let deleteTransport = MockTransport(status: 204)
        let deleteAPI = IPv64.mock(deleteTransport).failover
        try await deleteAPI.removeMonitor(policy: "12", healthcheck: "tok")
        try await deleteAPI.removeRule(policy: "12", record: "4711")
        #expect(deleteTransport.requests.map(\.relativePath) == [
            "/failover/policies/12/monitors/tok", "/failover/policies/12/rules/4711",
        ])
        #expect(deleteTransport.requests.allSatisfy { $0.httpMethod == "DELETE" })
    }

    @Test("409 problem+json becomes IPv64Error.api")
    func conflict() async throws {
        let transport = MockTransport(status: 409, json: """
        {"type":"https://ipv64.net/api/v2/errors#failover_active","title":"Conflict","status":409,
         "detail":"Failover is active.","code":"failover_active"}
        """)
        do {
            try await IPv64.mock(transport).failover.delete("12")
            Issue.record("Expected an error")
        } catch let IPv64Error.api(problem) {
            #expect(problem.code == "failover_active")
        }
    }
}
