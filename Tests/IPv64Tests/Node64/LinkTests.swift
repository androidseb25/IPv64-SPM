import Foundation
import Testing
@testable import IPv64

@Suite("Node64 link")
struct Node64LinkTests {
    @Test("LinkStatus decodes")
    func decodeStatus() throws {
        let json = #"{"linked":true,"connected":true,"account_id":"42","plan":"pro","node_name":"Home","location":"Berlin","remote_mgmt":"full","hub":"hub.ipv64.net","last_sync_at":"2026-10-27T10:00:00Z","outbox":2,"conflicts":1,"requesting":false,"online_limit":5,"checks_today":3,"checks_limit":100,"locations_per_check":2,"local_notifications":true}"#
        let status = try IPv64Coding.makeDecoder().decode(Node64.LinkStatus.self, from: Data(json.utf8))
        #expect(status.accountID == "42")
        #expect(status.remoteMgmt == .full)
        #expect(status.locationsPerCheck == 2)
        #expect(status.localNotifications == true)
    }

    @Test("connect sends remote_mgmt and accepts a 202")
    func connect() async throws {
        let transport = MockTransport(status: 202, json: #"{"linked":false,"requesting":true}"#)
        let status = try await Node64.mock(transport).link.connect(location: "Berlin", remoteManagement: .read)
        #expect(status.requesting == true)
        #expect(transport.lastRequest?.nodeRelativePath == "/link/apikey")
        #expect(transport.lastRequest?.jsonBody == .object(["location": .string("Berlin"), "remote_mgmt": .string("read")]))
    }

    @Test("unlink sends keep_checks and handles 204")
    func unlink() async throws {
        let transport = MockTransport(status: 204, body: Data())
        try await Node64.mock(transport).link.unlink(keepChecks: true)
        #expect(transport.lastRequest?.nodeRelativePath == "/link/unlink")
        #expect(transport.lastRequest?.jsonBody == .object(["keep_checks": .bool(true)]))
    }

    @Test("conflicts decode and resolve builds the path")
    func conflicts() async throws {
        let transport = MockTransport(json: #"[{"id":5,"entity":"check","entity_id":"abc","name":"Web","local_op":"update","local":{"a":1},"server":{"a":2},"server_revision":8,"created_at":"2026-10-27T10:00:00Z"}]"#)
        let conflicts = try await Node64.mock(transport).link.conflicts()
        #expect(conflicts.first?.entityID == "abc")
        #expect(conflicts.first?.server == .object(["a": .number(2)]))

        let resolve = MockTransport(status: 204, body: Data())
        try await Node64.mock(resolve).link.resolveConflict(5, keep: .local)
        #expect(resolve.lastRequest?.nodeRelativePath == "/link/conflicts/5")
        #expect(resolve.lastRequest?.jsonBody == .object(["keep": .string("local")]))
    }

    @Test("updateSettings and ipv64 key calls")
    func settingsAndKey() async throws {
        let settings = MockTransport(json: #"{"local_notifications":true}"#)
        let result = try await Node64.mock(settings).link.updateSettings(localNotifications: true)
        #expect(result.localNotifications == true)
        #expect(settings.lastRequest?.nodeRelativePath == "/link/settings")

        let account = MockTransport(json: #"{"key_stored":true,"account":"me","account_id":11,"plan":"pro","key_name":"node","checked_at":"2026-10-27T10:00:00Z","expires_at":"2027-10-27T10:00:00Z","days_left":365}"#)
        let info = try await Node64.mock(account).link.storeIPv64Key("ipv64-key")
        #expect(info.accountID == 11)
        #expect(info.daysLeft == 365)
        #expect(account.lastRequest?.httpMethod == "PUT")
        #expect(account.lastRequest?.nodeRelativePath == "/ipv64/key")
        #expect(account.lastRequest?.jsonBody == .object(["key": .string("ipv64-key")]))

        _ = try await Node64.mock(account).link.ipv64Account()
        #expect(account.lastRequest?.nodeRelativePath == "/ipv64")

        let removed = MockTransport(status: 204, body: Data())
        try await Node64.mock(removed).link.removeIPv64Key()
        #expect(removed.lastRequest?.httpMethod == "DELETE")
    }

    @Test("A 409 error becomes Node64Error.api")
    func apiError() async throws {
        let transport = MockTransport(status: 409, json: #"{"error":"schon verknüpft"}"#, headers: ["Content-Type": "application/json"])
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).link.connect()
        }
        #expect(error?.statusCode == 409)
    }
}
