import Foundation
import Testing
@testable import IPv64

@Suite("DNS64")
struct DNS64Tests {
    static let token = "Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z"

    static let clientJSON = """
    {"id":"Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z","name":"Familie","client_id":"k3x9m2","state":"applying",
    "blocking_enabled":true,"blocklists":["ads","threats"],
    "servers":[{"location":"Falkenstein","hostname":"dns64-1.ipv64.net","doh":"https://dns64-1.ipv64.net/k3x9m2",
    "dot":"k3x9m2.dns64-1.ipv64.net","doq":"k3x9m2.dns64-1.ipv64.net","ipv6":"2001:db8:53::k3:x9m2",
    "ipv4_shared":"203.0.113.53","ipv6_shared":"2001:db8:53::53","stamps":{"doh":"sdns://AgcAAA","dot":"sdns://AwcAAA","doq":"sdns://BAcAAA"}}],
    "queries_total":12000,"queries_blocked":800,"created_at":"2026-10-10T12:00:00+02:00",
    "rules":[{"id":3,"domain":"example.com","action":"block","state":"ready"}],
    "sources":[{"id":"8","kind":"ip","address":"203.0.113.10"},{"id":"tok","kind":"record","address":"203.0.113.11","fqdn":"home.beispiel.ipv64.de"}]}
    """

    @Test("DNS64Client decodes the spec example")
    func decode() throws {
        let client = try IPv64Coding.makeDecoder().decode(DNS64Client.self, from: Data(Self.clientJSON.utf8))
        #expect(client.clientID == "k3x9m2")
        #expect(client.state == .applying)
        #expect(client.blocklists == [.ads, .threats])
        let server = try #require(client.servers?.first)
        #expect(server.ipv4Shared == "203.0.113.53")
        #expect(server.stamps?.doh == "sdns://AgcAAA")
        #expect(client.queriesBlocked == 800)
        #expect(client.rules?.first?.action == .block)
        #expect(client.sources?.last?.kind == .record)
        #expect(client.sources?.last?.fqdn == "home.beispiel.ipv64.de")
    }

    @Test("DNS64Client tolerates null stamps and client_id")
    func decodeNulls() throws {
        let json = #"{"id":"x","client_id":null,"servers":[{"stamps":null}]}"#
        let client = try IPv64Coding.makeDecoder().decode(DNS64Client.self, from: Data(json.utf8))
        #expect(client.clientID == nil)
        #expect(client.servers?.first?.stamps == nil)
    }

    @Test("POST /dns64/clients accepts with 202")
    func create() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":\#(Self.clientJSON)}"#)
        let created = try await IPv64.mock(transport).dns64.create(name: "Familie")
        #expect(created.state == .applying)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/dns64/clients")
        #expect(request.jsonBody == .object(["name": .string("Familie")]))
    }

    @Test("List and get")
    func listAndGet() async throws {
        let listTransport = MockTransport(json: #"{"data":[\#(Self.clientJSON)]}"#)
        #expect(try await IPv64.mock(listTransport).dns64.list().count == 1)
        #expect(listTransport.lastRequest?.relativePath == "/dns64/clients")

        let getTransport = MockTransport(json: #"{"data":\#(Self.clientJSON)}"#)
        _ = try await IPv64.mock(getTransport).dns64.get(Self.token)
        #expect(getTransport.lastRequest?.relativePath == "/dns64/clients/\(Self.token)")
    }

    @Test("PATCH sends only provided fields")
    func update() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.clientJSON)}"#)
        _ = try await IPv64.mock(transport).dns64.update(Self.token, blocklists: [.ads, .threats])
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PATCH")
        #expect(request.jsonBody == .object(["blocklists": .array([.string("ads"), .string("threats")])]))
    }

    @Test("DELETE returns the deleting state with 202")
    func delete() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":{"id":"\#(Self.token)","state":"deleting"}}"#)
        let result = try await IPv64.mock(transport).dns64.delete(Self.token)
        #expect(result.state == .deleting)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
    }

    @Test("Rules: create and delete")
    func rules() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":\#(Self.clientJSON)}"#)
        _ = try await IPv64.mock(transport).dns64.rules.create(client: Self.token, domain: "example.com", action: .block)
        let request = try #require(transport.lastRequest)
        #expect(request.relativePath == "/dns64/clients/\(Self.token)/rules")
        #expect(request.jsonBody == .object(["domain": .string("example.com"), "action": .string("block")]))

        let deleteTransport = MockTransport(status: 204, body: Data())
        try await IPv64.mock(deleteTransport).dns64.rules.delete(3, client: Self.token)
        #expect(deleteTransport.lastRequest?.relativePath == "/dns64/clients/\(Self.token)/rules/3")
        #expect(deleteTransport.lastRequest?.httpMethod == "DELETE")
    }

    @Test("Sources: add and delete")
    func sources() async throws {
        let transport = MockTransport(status: 202, json: #"{"data":\#(Self.clientJSON)}"#)
        _ = try await IPv64.mock(transport).dns64.sources.add(client: Self.token, record: "4711")
        let request = try #require(transport.lastRequest)
        #expect(request.relativePath == "/dns64/clients/\(Self.token)/sources")
        #expect(request.jsonBody == .object(["record": .string("4711")]))

        let deleteTransport = MockTransport(status: 204, body: Data())
        try await IPv64.mock(deleteTransport).dns64.sources.delete("tok", client: Self.token)
        #expect(deleteTransport.lastRequest?.relativePath == "/dns64/clients/\(Self.token)/sources/tok")
    }

    @Test("409 problem exposes code and retry_after")
    func conflict() async throws {
        let transport = MockTransport(status: 409, json: """
        {"type":"https://ipv64.net/api/v2/errors#client_busy","title":"Conflict","status":409,
        "detail":"Client is being applied.","code":"client_busy","retry_after":5}
        """)
        do {
            _ = try await IPv64.mock(transport).dns64.rules.create(client: Self.token, domain: "example.com")
            Issue.record("Expected an error")
        } catch let IPv64Error.api(problem) {
            #expect(problem.code == "client_busy")
            #expect(problem.retryAfter == 5)
        }
    }
}
