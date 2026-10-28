import Foundation
import Testing
@testable import IPv64

@Suite("Meta")
struct MetaTests {
    @Test("GET / decodes API info without sending the API key")
    func info() async throws {
        let transport = MockTransport(json: """
        {"data":{"name":"IPv64.net API","version":"2.0.0","documentation":"https://ipv64.net/api/v2/docs","time":"2026-10-10T12:00:00+02:00"}}
        """)
        let info = try await IPv64.mock(transport).meta.info()

        #expect(info.name == "IPv64.net API")
        #expect(info.time == Date(timeIntervalSince1970: 1_791_626_400))
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.relativePath == "/")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("GET /ip decodes the address family")
    func ip() async throws {
        let transport = MockTransport(json: #"{"data":{"ip":"203.0.113.10","family":"ipv4"}}"#)
        let result = try await IPv64.mock(transport).meta.ip()

        #expect(result.ip == "203.0.113.10")
        #expect(result.family == .ipv4)
    }

    @Test("GET /health decodes status and version")
    func health() async throws {
        let transport = MockTransport(json: #"{"data":{"status":"ok","version":"2.0.0"}}"#)
        let health = try await IPv64.mock(transport).meta.health()

        #expect(health == APIHealth(status: "ok", version: "2.0.0"))
        #expect(transport.lastRequest?.relativePath == "/health")
    }

    @Test("GET /openapi.json returns the document without a data envelope")
    func openAPIDocument() async throws {
        let transport = MockTransport(json: #"{"openapi":"3.1.0","info":{"title":"IPv64.net API"}}"#)
        let document = try await IPv64.mock(transport).meta.openAPIDocument()

        #expect(document["openapi"] == "3.1.0")
        #expect(document["info"]?["title"] == "IPv64.net API")
        let request = try #require(transport.lastRequest)
        #expect(request.relativePath == "/openapi.json")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }
}
