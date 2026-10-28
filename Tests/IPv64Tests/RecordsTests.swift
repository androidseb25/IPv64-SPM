import Foundation
import Testing
@testable import IPv64

@Suite("Records")
struct RecordsTests {
    static let recordJSON = """
    {"id":4711,"domain_id":17597,"domain":"beispiel.ipv64.de","prefix":"_acme-challenge","fqdn":"_acme-challenge.beispiel.ipv64.de","type":"TXT","content":"abc123","ttl":60,"state":"active","pending_dns":true,"token":"tok"}
    """

    @Test("GET /domains/{domain}/records sends filters")
    func list() async throws {
        let transport = MockTransport(json: #"{"data":[\#(Self.recordJSON)]}"#)
        let records = try await IPv64.mock(transport).records.list(domain: "beispiel.ipv64.de", type: .txt, prefix: "_acme-challenge")

        #expect(records.first?.pendingDNS == true)
        #expect(transport.lastRequest?.relativePath == "/domains/beispiel.ipv64.de/records?type=TXT&prefix=_acme-challenge")
    }

    @Test("POST /domains/{domain}/records sends the body")
    func create() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.recordJSON)}"#)
        let record = try await IPv64.mock(transport).records.create(
            domain: "beispiel.ipv64.de", type: .txt, prefix: "_acme-challenge", content: "abc123"
        )

        #expect(record.id == 4711)
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.jsonBody == .object(["type": "TXT", "prefix": "_acme-challenge", "content": "abc123"]))
    }

    @Test("DELETE /domains/{domain}/records deletes by content with 204")
    func deleteByContent() async throws {
        let transport = MockTransport(status: 204)
        try await IPv64.mock(transport).records.delete(
            domain: "beispiel.ipv64.de", type: .txt, content: "a b+c", prefix: "_acme-challenge"
        )

        #expect(transport.lastRequest?.httpMethod == "DELETE")
        let path = try #require(transport.lastRequest?.relativePath)
        #expect(path.hasPrefix("/domains/beispiel.ipv64.de/records?type=TXT&content=a%20b%2Bc"))
        #expect(path.hasSuffix("&prefix=_acme-challenge"))
    }

    @Test("GET /records/{record} accepts a token")
    func get() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.recordJSON)}"#)
        let record = try await IPv64.mock(transport).records.get("tok")

        #expect(record.token == "tok")
        #expect(transport.lastRequest?.relativePath == "/records/tok")
    }

    @Test("PATCH /records/{record} sends only provided fields")
    func update() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.recordJSON)}"#)
        _ = try await IPv64.mock(transport).records.update("4711", content: "203.0.113.20")

        #expect(transport.lastRequest?.httpMethod == "PATCH")
        #expect(transport.lastRequest?.relativePath == "/records/4711")
        #expect(transport.lastRequest?.jsonBody == .object(["content": "203.0.113.20"]))
    }

    @Test("DELETE /records/{record} accepts 204")
    func delete() async throws {
        let transport = MockTransport(status: 204)
        try await IPv64.mock(transport).records.delete("4711")
        #expect(transport.lastRequest?.relativePath == "/records/4711")
    }

    @Test("Locked records surface the error code")
    func locked() async throws {
        let transport = MockTransport(status: 409, json: """
        {"type":"about:blank","title":"Conflict","status":409,"detail":"Record is locked.","code":"record_locked"}
        """)
        let error = await #expect(throws: IPv64Error.self) {
            try await IPv64.mock(transport).records.update("1", content: "x")
        }
        #expect(error?.code == "record_locked")
    }
}
