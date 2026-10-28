import Foundation
import Testing
@testable import IPv64

@Suite("Account and API keys")
struct AccountTests {
    @Test("GET /me decodes plan, usage and auth")
    func me() async throws {
        let transport = MockTransport(json: """
        {"data":{"id":522,"email":"max@example.com","username":null,"registered_at":"2026-10-10T12:00:00+02:00",
        "plan":{"id":2,"name":"VIP","valid_until":null},
        "usage":{"dyndns_domains":{"used":2,"limit":10},"own_domains":{"used":1,"limit":null},
        "vpn_traffic_gb":{"used":1.5,"limit":100,"limited":false},"cdn_traffic_gb":{"used":0.5,"limit":null}},
        "log_retention_days":90,
        "auth":{"type":"api_key","key_id":75043,"key_name":"Mein Server","acting_for":1234,"acting_by":522}}}
        """)
        let me = try await IPv64.mock(transport).account.me()

        #expect(me.id == 522)
        #expect(me.username == nil)
        #expect(me.plan?.name == "VIP")
        #expect(me.usage?.dyndnsDomains?.limit == 10)
        #expect(me.usage?.ownDomains?.limit == nil)
        #expect(me.usage?.vpnTrafficGB?.limited == false)
        #expect(me.auth?.type == .apiKey)
        #expect(me.auth?.actingFor == 1234)
        #expect(transport.lastRequest?.relativePath == "/me")
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
    }

    @Test("actAs sends the X-IPv64-Act-As header")
    func actAsHeader() async throws {
        let transport = MockTransport(json: #"{"data":{"id":1}}"#)
        _ = try await IPv64.mock(transport, actAs: "kunde@example.com").account.me()

        #expect(transport.lastRequest?.value(forHTTPHeaderField: "X-IPv64-Act-As") == "kunde@example.com")

        let plain = MockTransport(json: #"{"data":{"id":1}}"#)
        _ = try await IPv64.mock(plain).account.me()
        #expect(plain.lastRequest?.value(forHTTPHeaderField: "X-IPv64-Act-As") == nil)
    }

    @Test("GET /me/logs sends query and exposes the next_before cursor")
    func logsPagination() async throws {
        let transport = MockTransport(json: """
        {"data":[{"id":83448927,"domain_id":null,"title":"API Key","message":"New API Key 'test' created.","time":"2026-10-10T12:00:00+02:00"}],
        "meta":{"limit":50,"next_before":83448900,"retention_days":90}}
        """)
        let client = IPv64.mock(transport)
        let page = try await client.account.logs(limit: 50, before: 83_448_927, since: Date(timeIntervalSince1970: 1_791_626_400))

        #expect(page.items.count == 1)
        #expect(page.items.first?.id == 83_448_927)
        #expect(page.items.first?.domainID == nil)
        #expect(page.meta?.nextBefore == 83_448_900)
        #expect(page.meta?.retentionDays == 90)
        let path = try #require(transport.lastRequest?.relativePath)
        #expect(path.hasPrefix("/me/logs?"))
        #expect(path.contains("limit=50"))
        #expect(path.contains("before=83448927"))
        #expect(path.contains("since="))

        // Follow the cursor.
        let next = try #require(page.meta?.nextBefore)
        _ = try await client.account.logs(before: next)
        #expect(transport.lastRequest?.relativePath == "/me/logs?before=83448900")
    }

    @Test("GET /me/logs: next_before null marks the end")
    func logsEnd() async throws {
        let transport = MockTransport(json: #"{"data":[],"meta":{"limit":50,"next_before":null,"retention_days":90}}"#)
        let page = try await IPv64.mock(transport).account.logs()
        #expect(page.meta?.nextBefore == nil)
        #expect(transport.lastRequest?.relativePath == "/me/logs")
    }

    @Test("GET /me/account-links decodes both directions")
    func links() async throws {
        let transport = MockTransport(json: """
        {"data":{"shared_with":[{"id":1,"direction":"shared_with","email":"admin@example.com","status":"active","created_at":"2026-10-10T12:00:00+02:00","last_used_at":null}],
        "managed":[{"id":2,"direction":"managed","email":"kunde@example.com","status":"pending","account_id":1234}]}}
        """)
        let links = try await IPv64.mock(transport).account.links()

        #expect(links.sharedWith?.first?.status == .active)
        #expect(links.sharedWith?.first?.lastUsedAt == nil)
        #expect(links.managed?.first?.direction == .managed)
        #expect(links.managed?.first?.accountID == 1234)
    }

    @Test("GET /api-keys decodes keys")
    func listKeys() async throws {
        let transport = MockTransport(json: """
        {"data":[{"id":303,"name":"Mein Server","token_hint":"1ZK4…Rx5e","created_at":"2026-10-10T12:00:00+02:00","expires_at":null,"expired":false,"uses":42}]}
        """)
        let keys = try await IPv64.mock(transport).apiKeys.list()

        #expect(keys.first?.tokenHint == "1ZK4…Rx5e")
        #expect(keys.first?.expiresAt == nil)
        #expect(keys.first?.uses == 42)
    }

    @Test("POST /api-keys sends the body and decodes the full token")
    func createKey() async throws {
        let transport = MockTransport(status: 201, json: """
        {"data":{"id":304,"name":"Backup-Server","token_hint":"Ab3d…Xy4z","expired":false,"uses":0,"token":"Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z"}}
        """)
        let key = try await IPv64.mock(transport).apiKeys.create(name: "Backup-Server", expiresIn: 2_592_000)

        #expect(key.token == "Ab3dEf6hIj9kLm2nOp5qRs8tUv1wXy4z")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/api-keys")
        #expect(request.jsonBody == .object(["name": "Backup-Server", "expires_in": 2_592_000]))
    }

    @Test("DELETE /api-keys/{id} accepts 204")
    func deleteKey() async throws {
        let transport = MockTransport(status: 204)
        try await IPv64.mock(transport).apiKeys.delete(303)

        #expect(transport.lastRequest?.httpMethod == "DELETE")
        #expect(transport.lastRequest?.relativePath == "/api-keys/303")
    }

    @Test("API errors surface as IPv64Error.api with a code")
    func apiError() async throws {
        let transport = MockTransport(status: 400, json: """
        {"type":"about:blank","title":"Bad Request","status":400,"detail":"Cannot delete own key.","code":"cannot_delete_current_key"}
        """)
        let error = await #expect(throws: IPv64Error.self) {
            try await IPv64.mock(transport).apiKeys.delete(1)
        }
        #expect(error?.code == "cannot_delete_current_key")
    }
}
