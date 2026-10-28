import Foundation
import Testing
@testable import IPv64

@Suite("Integrations")
struct IntegrationsTests {
    static let json = """
    {"id":12,"type":"telegram","name":"Mein Telegram","status":"active","default":false,
    "options":{"chatid":"123456789","apitoken":"…AbCd"},"created_at":"2026-10-10T12:00:00+02:00","last_used_at":null,"uses":17}
    """

    @Test("GET /integrations decodes and sends include_secrets")
    func list() async throws {
        let transport = MockTransport(json: #"{"data":[\#(Self.json)]}"#)
        let items = try await IPv64.mock(transport).integrations.list(includeSecrets: true)

        let item = try #require(items.first)
        #expect(item.type == .telegram)
        #expect(item.status == .active)
        #expect(item.isDefault == false)
        #expect(item.options?["chatid"] == "123456789")
        #expect(item.lastUsedAt == nil)
        #expect(transport.lastRequest?.relativePath == "/integrations?include_secrets=true")
    }

    @Test("POST /integrations encodes type-specific fields")
    func create() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.json)}"#)
        _ = try await IPv64.mock(transport).integrations.create(
            IntegrationInput(type: .ntfy, name: "ntfy", isDefault: true, serverURL: "https://ntfy.sh/t", priorityDown: 4, priorityUp: 3)
        )

        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.jsonBody == .object([
            "type": "ntfy", "name": "ntfy", "default": true,
            "server_url": "https://ntfy.sh/t", "priority_down": 4, "priority_up": 3,
        ]))
    }

    @Test("GET /integrations/{id}")
    func get() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.json)}"#)
        let item = try await IPv64.mock(transport).integrations.get(12)

        #expect(item.uses == 17)
        #expect(transport.lastRequest?.relativePath == "/integrations/12")
    }

    @Test("PATCH /integrations/{id} sends name and default")
    func update() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.json)}"#)
        _ = try await IPv64.mock(transport).integrations.update(12, isDefault: true)

        #expect(transport.lastRequest?.httpMethod == "PATCH")
        #expect(transport.lastRequest?.jsonBody == .object(["default": true]))
    }

    @Test("DELETE /integrations/{id} accepts 204")
    func delete() async throws {
        let transport = MockTransport(status: 204)
        try await IPv64.mock(transport).integrations.delete(12)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
    }

    @Test("POST /integrations/{id}/test")
    func sendTest() async throws {
        let transport = MockTransport(json: #"{"data":{"sent":true}}"#)
        let result = try await IPv64.mock(transport).integrations.sendTest(0)

        #expect(result.sent == true)
        #expect(transport.lastRequest?.relativePath == "/integrations/0/test")
    }

    @Test("Rate limited test messages surface the error code")
    func rateLimited() async throws {
        let transport = MockTransport(status: 429, json: """
        {"type":"about:blank","title":"Too Many Requests","status":429,"detail":"Wait.","code":"rate_limited"}
        """)
        let error = await #expect(throws: IPv64Error.self) {
            try await IPv64.mock(transport).integrations.sendTest(1)
        }
        #expect(error?.code == "rate_limited")
    }
}
