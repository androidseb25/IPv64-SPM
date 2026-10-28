import Foundation
import Testing
@testable import IPv64

@Suite("Node64 DNS64 records")
struct Node64DNS64RecordsTests {
    private let recordJSON = """
    {"id":7,"name":"nas.home.lan","type":"A","value":"192.168.1.10","ttl":300,"enabled":true,
     "created_at":"2026-10-27T08:00:00Z","comment":"NAS","no_ptr":false,"local_only":true,"dynamic":false}
    """

    @Test("record decodes all fields")
    func decode() async throws {
        let transport = MockTransport(json: "[\(recordJSON)]")
        let records = try await Node64.mock(transport).dns64.records.list()
        let record = try #require(records.first)
        #expect(record.id == 7)
        #expect(record.type == .a)
        #expect(record.value == "192.168.1.10")
        #expect(record.ttl == 300)
        #expect(record.createdAt != nil)
        #expect(record.noPTR == false)
        #expect(record.localOnly == true)
        #expect(record.dynamic == false)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/records")
    }

    @Test("create sends snake_case body")
    func create() async throws {
        let transport = MockTransport(status: 201, json: recordJSON)
        let record = try await Node64.mock(transport).dns64.records.create(
            .init(name: "nas.home.lan", type: .a, value: "192.168.1.10", ttl: 300, noPTR: true)
        )
        #expect(record.id == 7)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.jsonBody == .object([
            "name": .string("nas.home.lan"),
            "type": .string("A"),
            "value": .string("192.168.1.10"),
            "ttl": .number(300),
            "no_ptr": .bool(true),
        ]))
    }

    @Test("update uses PUT with the numeric id")
    func update() async throws {
        let transport = MockTransport(json: recordJSON)
        _ = try await Node64.mock(transport).dns64.records.update(7, .init(name: "nas.home.lan", type: .a, value: "192.168.1.11"))
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/records/7")
    }

    @Test("delete, enable and disable accept 204")
    func noContent() async throws {
        let transport = MockTransport(status: 204, body: Data())
        let records = Node64.mock(transport).dns64.records
        try await records.delete(7)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/records/7")
        try await records.enable(7)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/records/7/enable")
        try await records.disable(7)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/records/7/disable")
        #expect(transport.requests.count == 3)
    }

    @Test("importRecords sends text/plain with the zone")
    func importRecords() async throws {
        let transport = MockTransport(json: #"{"added":2,"skipped":1,"invalid":0}"#)
        let result = try await Node64.mock(transport).dns64.records.importRecords("192.168.1.10 nas\n", zone: "home.lan")
        #expect(result.added == 2)
        #expect(result.skipped == 1)
        let request = try #require(transport.lastRequest)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "text/plain")
        #expect(request.httpBody == Data("192.168.1.10 nas\n".utf8))
        #expect(request.nodeRelativePath == "/dns64/records/import?zone=home.lan")
    }

    @Test("export returns the file and sends the format")
    func export() async throws {
        let body = Data("192.168.1.10 nas.home.lan\n".utf8)
        let transport = MockTransport(status: 200, body: body, headers: ["Content-Type": "text/plain"])
        let data = try await Node64.mock(transport).dns64.records.export(format: .csv)
        #expect(data == body)
        #expect(transport.lastRequest?.nodeRelativePath == "/dns64/records/export?format=csv")
    }

    @Test("record errors become Node64Error.api")
    func notFound() async throws {
        let transport = MockTransport(status: 404, json: #"{"error":"Nicht gefunden"}"#, headers: ["Content-Type": "application/json"])
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).dns64.records.delete(99)
        }
        guard case .api(let document) = error else {
            Issue.record("Expected an API error")
            return
        }
        #expect(document.status == 404)
    }
}
