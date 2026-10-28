import Foundation
import Testing
@testable import IPv64

@Suite("Node64 core")
struct Node64CoreTests {
    @Test("Requests go to the configured node with a Bearer API key and no envelope")
    func versionRequest() async throws {
        let transport = MockTransport(json: """
        {"version":"1.2.0","started_at":"2026-10-27T08:00:00Z","hostname":"node","time":"2026-10-27T10:00:00Z"}
        """)

        let version = try await Node64.mock(transport).node.version()

        #expect(version.version == "1.2.0")
        #expect(version.startedAt == Date(timeIntervalSince1970: 1_793_088_000))
        let request = try #require(transport.lastRequest)
        #expect(request.url?.absoluteString == "https://node.example.com/api/version")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer node64_test")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
        #expect(request.value(forHTTPHeaderField: "X-IPv64-Act-As") == nil)
    }

    @Test("Public endpoints send neither the API key nor X-Agent-Actor")
    func publicEndpoint() async throws {
        let transport = MockTransport(json: #"{"status":"ok","version":"1.2.0"}"#)

        let health = try await Node64.mock(transport, agentActor: "app").node.health()

        #expect(health.status == "ok")
        let request = try #require(transport.lastRequest)
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(request.value(forHTTPHeaderField: "X-Agent-Actor") == nil)
    }

    @Test("X-Agent-Actor is sent on authenticated requests")
    func agentActor() async throws {
        let transport = MockTransport(json: #"{"version":"1.2.0"}"#)

        _ = try await Node64.mock(transport, agentActor: "Home Assistant").node.version()

        #expect(transport.lastRequest?.value(forHTTPHeaderField: "X-Agent-Actor") == "Home Assistant")
    }

    @Test("Without an API key, protected endpoints fail before sending")
    func missingAPIKey() async throws {
        let transport = MockTransport(json: "{}")
        let node = Node64(baseURL: URL(string: "https://node.example.com/api")!, apiKey: nil, transport: transport)

        await #expect {
            try await node.node.version()
        } throws: { error in
            guard case Node64Error.missingAPIKey = error else { return false }
            return true
        }
        #expect(transport.requests.isEmpty)
    }

    @Test("Error documents become Node64Error.api with status, field and code")
    func errorDocument() async throws {
        let transport = MockTransport(
            status: 409,
            json: #"{"error":"Kein API-Key","code":"no_api_key","text":"Bitte API-Key hinterlegen."}"#,
            headers: ["Content-Type": "application/json"]
        )

        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).node.version()
        }

        guard case .api(let document) = error else {
            Issue.record("Expected an API error, got \(String(describing: error))")
            return
        }
        #expect(document.status == 409)
        #expect(document.error == "Kein API-Key")
        #expect(error?.code == "no_api_key")
        #expect(error?.errorDescription == "Bitte API-Key hinterlegen.")
    }

    @Test("Validation errors keep per-field messages")
    func fieldErrors() async throws {
        let transport = MockTransport(status: 400, json: #"{"error":"invalid","fields":{"port":"out of range"}}"#)

        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).node.version()
        }

        guard case .api(let document) = error else {
            Issue.record("Expected an API error, got \(String(describing: error))")
            return
        }
        #expect(document.fields == ["port": "out of range"])
    }

    @Test("429 without a body still reports Retry-After")
    func rateLimited() async throws {
        let transport = MockTransport(status: 429, body: Data("too many requests".utf8), headers: ["Retry-After": "10"])

        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).node.version()
        }

        guard case .api(let document) = error else {
            Issue.record("Expected an API error, got \(String(describing: error))")
            return
        }
        #expect(document.retryAfter == 10)
        #expect(error?.statusCode == 429)
    }

    @Test("Error status without a JSON document becomes httpStatus")
    func plainError() async throws {
        let transport = MockTransport(status: 503, body: Data("<html>".utf8))

        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).node.version()
        }

        #expect(error?.statusCode == 503)
        #expect(error?.code == nil)
    }

    @Test("Prometheus metrics are returned as text")
    func metrics() async throws {
        let transport = MockTransport(status: 200, body: Data("node64_up 1\n".utf8), headers: ["Content-Type": "text/plain"])

        let text = try await Node64.mock(transport).node.metrics()

        #expect(text == "node64_up 1\n")
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Accept") == "text/plain")
    }

    @Test("Empty or undocumented bodies decode as JSONValue")
    func sendJSON() async throws {
        let empty = MockTransport(status: 201)
        let filled = MockTransport(json: #"{"token":"abc"}"#)

        let emptyValue = try await Node64.mock(empty).sendJSON(Request(.post, "/x"))
        let filledValue = try await Node64.mock(filled).sendJSON(Request(.post, "/x"))

        #expect(emptyValue == .null)
        #expect(filledValue["token"]?.stringValue == "abc")
    }
}
