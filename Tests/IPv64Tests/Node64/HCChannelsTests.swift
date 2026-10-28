import Foundation
import Testing
@testable import IPv64

@Suite("Node64 Channels")
struct Node64ChannelsTests {
    static let channelJSON = """
    {"id":7,"type":"telegram","name":"Mein Telegram","config":{"bot_token":"***","chat_id":"123"},"enabled":true,
     "default":true,"lang":"de","notify_down":true,"notify_up":false,"execution":"node","revision":2,
     "last_used_at":"2026-10-27T08:00:00Z","last_error":"","created_at":"2026-10-01T08:00:00Z","updated_at":"2026-10-02T08:00:00Z"}
    """

    @Test("Channel decodes")
    func decodeChannel() throws {
        let channel = try IPv64Coding.makeDecoder().decode(Node64.Channel.self, from: Data(Self.channelJSON.utf8))
        #expect(channel.id == 7)
        #expect(channel.type == .telegram)
        #expect(channel.config?["chat_id"] == .string("123"))
        #expect(channel.isDefault == true)
        #expect(channel.notifyUp == false)
        #expect(channel.execution == .node)
        #expect(channel.createdAt == Date(timeIntervalSince1970: 1_790_841_600))
    }

    @Test("Delivery decodes")
    func decodeDelivery() throws {
        let delivery = try IPv64Coding.makeDecoder().decode(Node64.Delivery.self, from: Data("""
        {"id":1,"time":"2026-10-27T08:00:00Z","event_id":"e1","channel_id":7,"channel":"Mein Telegram","kind":"down",
         "check_token":"abc","subject":"Down","ok":false,"error":"https://api.telegram.org: timeout"}
        """.utf8))
        #expect(delivery.channelID == 7)
        #expect(delivery.ok == false)
        #expect(delivery.checkToken == "abc")
    }

    @Test("include_secrets is sent as a query item")
    func listWithSecrets() async throws {
        let transport = MockTransport(json: "[\(Self.channelJSON)]")

        let channels = try await Node64.mock(transport).hc.channels.list(includeSecrets: true)

        #expect(channels.count == 1)
        #expect(transport.lastRequest?.nodeRelativePath == "/channels?include_secrets=true")
        let plain = MockTransport(json: "[]")
        _ = try await Node64.mock(plain).hc.channels.list()
        #expect(plain.lastRequest?.nodeRelativePath == "/channels")
    }

    @Test("Creating a channel sends type, config and default")
    func create() async throws {
        let transport = MockTransport(status: 201, json: Self.channelJSON)
        let input = Node64.ChannelInput(
            type: .telegram, name: "Mein Telegram",
            config: ["bot_token": .string("t"), "chat_id": .string("123")], isDefault: true
        )

        let channel = try await Node64.mock(transport).hc.channels.create(input)

        #expect(channel.id == 7)
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.jsonBody == .object([
            "type": .string("telegram"), "name": .string("Mein Telegram"),
            "config": .object(["bot_token": .string("t"), "chat_id": .string("123")]),
            "default": .bool(true),
        ]))
    }

    @Test("Updating a channel uses PUT")
    func update() async throws {
        let transport = MockTransport(json: Self.channelJSON)
        try await Node64.mock(transport).hc.channels.update(7, .init(name: "Neu", enabled: false))
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.nodeRelativePath == "/channels/7")
        #expect(transport.lastRequest?.jsonBody == .object(["name": .string("Neu"), "enabled": .bool(false)]))
    }

    @Test("Deleting a channel accepts 204")
    func delete() async throws {
        let transport = MockTransport(status: 204)
        try await Node64.mock(transport).hc.channels.delete(7)
        #expect(transport.lastRequest?.httpMethod == "DELETE")
    }

    @Test("sendTest decodes ok")
    func sendTest() async throws {
        let transport = MockTransport(json: #"{"ok":true}"#)
        let result = try await Node64.mock(transport).hc.channels.sendTest(7)
        #expect(result.ok == true)
        #expect(transport.lastRequest?.nodeRelativePath == "/channels/7/test")
    }

    @Test("A failed test (502) surfaces as an API error")
    func sendTestFails() async throws {
        let transport = MockTransport(status: 502, json: #"{"ok":false,"error":"timeout"}"#)
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).hc.channels.sendTest(7)
        }
        #expect(error?.statusCode == 502)
    }

    @Test("Channel types return raw JSON")
    func types() async throws {
        let transport = MockTransport(json: #"[{"type":"ntfy","fields":[]}]"#)
        let value = try await Node64.mock(transport).hc.channels.types()
        guard case .array(let items) = value else {
            Issue.record("Expected an array")
            return
        }
        #expect(items.count == 1)
        #expect(transport.lastRequest?.nodeRelativePath == "/channel-types")
    }

    @Test("Deliveries send limit, before and channel")
    func deliveries() async throws {
        let transport = MockTransport(json: "[]")
        _ = try await Node64.mock(transport).hc.channels.deliveries(limit: 20, before: 100, channel: 7)
        let path = try #require(transport.lastRequest).nodeRelativePath
        #expect(path.hasPrefix("/deliveries?"))
        #expect(path.contains("limit=20") && path.contains("before=100") && path.contains("channel=7"))
    }

    @Test("Unknown channel returns an API error")
    func notFound() async throws {
        let transport = MockTransport(status: 404, json: #"{"error":"channel not found"}"#)
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).hc.channels.get(99)
        }
        guard case .api(let document) = error else {
            Issue.record("Expected an API error")
            return
        }
        #expect(document.error == "channel not found")
    }
}
