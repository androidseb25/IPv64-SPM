import Foundation
import Testing
@testable import IPv64

@Suite("Node64 DNS64 forwards, rewrites, zones")
struct Node64DNS64ForwardingTests {
    @Test("Forward decodes with server state")
    func decodeForward() async throws {
        let json = """
        [{"id":1,"domain":"firma.local","servers":["10.8.0.1","tls://dns.firma.de"],"comment":"c","enabled":true,
          "created_at":"2026-10-27T10:00:00Z",
          "state":[{"label":"10.8.0.1","url":"10.8.0.1","requests":5,"errors":1,"avg_ms":2.5,"healthy":true,"last_error":"x","last_error_at":"2026-10-27T10:00:00Z"}],
          "local_only":true}]
        """
        let transport = MockTransport(json: json)
        let forwards = try await Node64.mock(transport).dns64.forwards.list()
        let forward = try #require(forwards.first)
        #expect(forward.servers.count == 2)
        #expect(forward.localOnly == true)
        #expect(forward.state?.first?.avgMs == 2.5)
        #expect(forward.state?.first?.lastErrorAt != nil)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/forwards")
    }

    @Test("Creating and updating a forward")
    func createUpdateForward() async throws {
        let transport = MockTransport(status: 201, json: #"{"id":1,"domain":"a.lan","servers":["10.0.0.1"]}"#)
        let input = Node64.DNS64ForwardInput(domain: "a.lan", servers: ["10.0.0.1"], localOnly: true)
        let created = try await Node64.mock(transport).dns64.forwards.create(input)
        #expect(created.id == 1)
        #expect(transport.lastRequest?.jsonBody?["local_only"]?.boolValue == true)
        #expect(transport.lastRequest?.jsonBody?["comment"] == nil)

        let put = MockTransport(json: #"{"id":1,"domain":"a.lan","servers":["10.0.0.1"]}"#)
        _ = try await Node64.mock(put).dns64.forwards.update(1, input)
        #expect(put.lastRequest?.httpMethod == "PUT")
        #expect(put.lastRequest?.nodeRelativePath == "/dns64/forwards/1")
    }

    @Test("Forward test result")
    func testForward() async throws {
        let transport = MockTransport(json: #"{"ok":true,"rcode":"NOERROR","server":"10.0.0.1","ms":3.2}"#)
        let result = try await Node64.mock(transport).dns64.forwards.test(4)
        #expect(result.ok == true)
        #expect(result.ms == 3.2)
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/forwards/4/test")
    }

    @Test("Rewrites decode and enable/delete use 204")
    func rewrites() async throws {
        let transport = MockTransport(json: #"[{"id":2,"name":"*.example.com","target":"nas.home.lan","enabled":false,"created_at":"2026-10-27T10:00:00Z"}]"#)
        let rewrites = try await Node64.mock(transport).dns64.rewrites.list()
        #expect(rewrites.first?.name == "*.example.com")
        #expect(rewrites.first?.enabled == false)

        let empty = MockTransport(status: 204)
        try await Node64.mock(empty).dns64.rewrites.enable(2)
        #expect(empty.lastRequest?.nodeRelativePath == "/dns64/rewrites/2/enable")
        try await Node64.mock(empty).dns64.rewrites.delete(2)
        #expect(empty.lastRequest?.httpMethod == "DELETE")

        let created = MockTransport(status: 201, json: #"{"id":3,"name":"a","target":"b"}"#)
        _ = try await Node64.mock(created).dns64.rewrites.create(.init(name: "a", target: "b"))
        #expect(created.lastRequest?.jsonBody?["target"]?.stringValue == "b")
    }

    @Test("Zone decodes and input omits nil")
    func zones() async throws {
        let json = """
        {"id":1,"name":"home.lan","authoritative":true,"devices":true,"enabled":true,"ttl":300,"refresh":3600,
         "retry":600,"expire":86400,"minimum":60,"hostmaster":"","dynamic":false,"tsig_name":"key","created_at":"2026-10-27T10:00:00Z"}
        """
        let transport = MockTransport(status: 201, json: json)
        let zone = try await Node64.mock(transport).dns64.zones.create(.init(name: "home.lan", ttl: 300))
        #expect(zone.tsigName == "key")
        #expect(zone.minimum == 60)
        #expect(transport.lastRequest?.jsonBody?["ttl"]?.intValue == 300)
        #expect(transport.lastRequest?.jsonBody?["retry"] == nil)
    }

    @Test("Zone file is returned as text")
    func zonefile() async throws {
        let transport = MockTransport(status: 200, body: Data("$TTL 300\n".utf8), headers: ["Content-Type": "text/plain"])
        let text = try await Node64.mock(transport).dns64.zones.zonefile(5)
        #expect(text == "$TTL 300\n")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/zones/5/zonefile")
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Accept") == "text/plain")
    }

    @Test("Zone enable and disable return 204")
    func zoneToggle() async throws {
        let transport = MockTransport(status: 204)
        try await Node64.mock(transport).dns64.zones.disable(5)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/zones/5/disable")
    }

    @Test("Validation errors become Node64Error.api")
    func apiError() async throws {
        let transport = MockTransport(status: 400, json: #"{"error":"Ungültig"}"#)
        let error = await #expect(throws: Node64Error.self) {
            _ = try await Node64.mock(transport).dns64.forwards.create(.init(domain: "", servers: []))
        }
        guard case .api(let document) = error else {
            Issue.record("Expected an API error")
            return
        }
        #expect(document.status == 400)
    }
}
