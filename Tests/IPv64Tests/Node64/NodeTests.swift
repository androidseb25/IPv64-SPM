import Foundation
import Testing
@testable import IPv64

@Suite("Node64 node admin")
struct Node64NodeTests {
    @Test("ModuleStatus, APIKey and AuditEntry decode")
    func decodeSchemas() throws {
        let decoder = IPv64Coding.makeDecoder()
        let module = try decoder.decode(Node64.ModuleStatus.self, from: Data(#"{"name":"dns64","version":"1.4.0","available":true,"enabled":true,"running":false,"path":"/dns64","last_error":"boom"}"#.utf8))
        #expect(module.id == "dns64")
        #expect(module.running == false)
        #expect(module.lastError == "boom")

        let key = try decoder.decode(Node64.APIKey.self, from: Data(#"{"id":3,"name":"Prometheus","hint":"..ab12","created_at":"2026-10-27T10:00:00Z","last_used_at":"2026-10-27T11:00:00Z"}"#.utf8))
        #expect(key.id == 3)
        #expect(key.lastUsedAt != nil)

        let entry = try decoder.decode(Node64.AuditEntry.self, from: Data(#"{"id":9,"time":"2026-10-27T10:00:00Z","actor":"admin","action":"settings.update","target":"node.name","details":"x","ip":"10.0.0.1","origin":"api:Prometheus (..ab12)"}"#.utf8))
        #expect(entry.origin == "api:Prometheus (..ab12)")
    }

    @Test("status decodes the nested link and boards")
    func status() async throws {
        let transport = MockTransport(json: #"{"node":{"id":"n1","name":"Home","uptime_seconds":5,"database_bytes":10},"link":{"linked":true,"remote_mgmt":"read","account_id":"7"},"modules":[{"name":"hc"}],"boards":[{"module":"hc","ok":3,"down":1}]}"#)
        let status = try await Node64.mock(transport).node.status()
        #expect(status.node?.uptimeSeconds == 5)
        #expect(status.link?.remoteMgmt == .read)
        #expect(status.boards?.first?.down == 1)
        #expect(transport.lastRequest?.nodeRelativePath == "/status")
    }

    @Test("modules sends changelog=1 and enable/disable percent-encode the name")
    func modules() async throws {
        let transport = MockTransport(json: #"[{"name":"dns64","changed":"2026-10-01","changelog":"- fix"}]"#)
        let modules = Node64.mock(transport).node.modules
        let list = try await modules.list(changelog: true)
        #expect(list.first?.changed == "2026-10-01")
        #expect(list.first?.changelog == .string("- fix"))
        #expect(transport.lastRequest?.nodeRelativePath == "/modules?changelog=1")
        _ = try await modules.list()
        #expect(transport.lastRequest?.nodeRelativePath == "/modules")
        try await modules.enable("a b")
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.nodeRelativePath == "/modules/a%20b/enable")
        try await modules.disable("dns64")
        #expect(transport.lastRequest?.nodeRelativePath == "/modules/dns64/disable")
    }

    @Test("updateSettings sends a flat object")
    func settings() async throws {
        let transport = MockTransport(json: #"{"node.name":"Neu"}"#)
        let result = try await Node64.mock(transport).node.updateSettings(["node.name": "Neu"])
        #expect(result["node.name"] == "Neu")
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.jsonBody == .object(["node.name": .string("Neu")]))
    }

    @Test("audit and logs build queries")
    func auditAndLogs() async throws {
        let transport = MockTransport(json: "[]")
        _ = try await Node64.mock(transport).node.audit(limit: 10, before: 99)
        #expect(transport.lastRequest?.nodeRelativePath == "/audit?limit=10&before=99")

        let logTransport = MockTransport(json: #"{"level":"info","lines":[{"msg":"x"}]}"#)
        let logs = try await Node64.mock(logTransport).node.logs(lines: 5)
        #expect(logs.lines?.count == 1)
        #expect(logTransport.lastRequest?.nodeRelativePath == "/logs?lines=5")
    }

    @Test("updateLogging encodes snake_case keys")
    func logging() async throws {
        let transport = MockTransport(json: #"{"level":"debug","modules":{"dns64":"inherit"}}"#)
        let result = try await Node64.mock(transport).node.updateLogging(level: .debug, resetMinutes: 30, modules: ["dns64": "inherit"])
        #expect(result.level == .debug)
        #expect(transport.lastRequest?.jsonBody == .object([
            "level": .string("debug"), "reset_minutes": .number(30), "modules": .object(["dns64": .string("inherit")]),
        ]))
    }

    @Test("retention decodes and sends only passed fields")
    func retention() async throws {
        let transport = MockTransport(json: #"{"raw_days":7,"hourly_days":0,"chart_detail":"high","audit_days":90,"options":{"raw_days":[1,7]}}"#)
        let result = try await Node64.mock(transport).node.updateRetention(rawDays: 7)
        #expect(result.auditDays == 90)
        #expect(result.options != nil)
        #expect(transport.lastRequest?.jsonBody == .object(["raw_days": .number(7)]))
    }

    @Test("API keys: create and delete (204)")
    func apiKeys() async throws {
        let created = MockTransport(status: 201, json: #"{"id":4,"name":"CI","hint":"..zz","created_at":"2026-10-27T10:00:00Z","key":"n64_secret"}"#)
        let key = try await Node64.mock(created).node.apiKeys.create(name: "CI")
        #expect(key.key == "n64_secret")
        #expect(created.lastRequest?.jsonBody == .object(["name": .string("CI")]))

        let revoked = MockTransport(status: 204, body: Data())
        try await Node64.mock(revoked).node.apiKeys.delete(4)
        #expect(revoked.lastRequest?.httpMethod == "DELETE")
        #expect(revoked.lastRequest?.nodeRelativePath == "/keys/4")
    }

    @Test("Database download and backup return raw data with the documented Accept header")
    func backupDownloads() async throws {
        let bytes = Data([1, 2, 3])
        let transport = MockTransport(status: 200, body: bytes)
        let node = Node64.mock(transport).node
        #expect(try await node.downloadDatabase() == bytes)
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Accept") == "application/vnd.sqlite3")
        #expect(try await node.createBackup(password: "12345678", includeStatistics: true) == bytes)
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Accept") == "application/octet-stream")
        #expect(transport.lastRequest?.jsonBody == .object(["password": .string("12345678"), "stats": .bool(true)]))
    }

    @Test("restoreBackup sends raw bytes with X-Backup-Password")
    func restoreRaw() async throws {
        let transport = MockTransport(status: 202, json: #"{"restarting":true,"bytes":12}"#)
        let result = try await Node64.mock(transport).node.restoreBackup(Data([9, 9]), password: "secret-pw")
        #expect(result.restarting == true)
        let request = try #require(transport.lastRequest)
        #expect(request.nodeRelativePath == "/backup/restore")
        #expect(request.value(forHTTPHeaderField: "X-Backup-Password") == "secret-pw")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/octet-stream")
        #expect(request.httpBody == Data([9, 9]))
    }

    @Test("restoreBackup multipart carries file and password parts")
    func restoreMultipart() async throws {
        let transport = MockTransport(status: 202, json: #"{"restarting":true}"#)
        _ = try await Node64.mock(transport).node.restoreBackup(file: Data("abc".utf8), password: "pw")
        let request = try #require(transport.lastRequest)
        #expect(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data") == true)
        let body = String(decoding: request.httpBody ?? Data(), as: UTF8.self)
        #expect(body.contains("name=\"file\""))
        #expect(body.contains("name=\"password\""))
    }

    @Test("export and import use X-Config-Password")
    func exportImport() async throws {
        let exportTransport = MockTransport(json: #"{"version":1}"#)
        let file = try await Node64.mock(exportTransport).node.exportConfiguration(secrets: .password, password: "12345678")
        #expect(file == .object(["version": .number(1)]))
        #expect(exportTransport.lastRequest?.jsonBody == .object(["secrets": .string("password"), "password": .string("12345678")]))

        let importTransport = MockTransport(json: #"{"imported":4,"problems":["x"]}"#)
        let result = try await Node64.mock(importTransport).node.importConfiguration(file, password: "pw")
        #expect(result.imported == 4)
        #expect(importTransport.lastRequest?.value(forHTTPHeaderField: "X-Config-Password") == "pw")
        #expect(importTransport.lastRequest?.jsonBody == file)
    }

    @Test("reset sends password and keep_checks")
    func reset() async throws {
        let transport = MockTransport(status: 202, json: #"{"restarting":true,"cleanup_problems":["tunnel"]}"#)
        let result = try await Node64.mock(transport).node.reset(password: "pw", keepChecks: true)
        #expect(result.cleanupProblems == ["tunnel"])
        #expect(transport.lastRequest?.jsonBody == .object(["password": .string("pw"), "keep_checks": .bool(true)]))
    }

    @Test("overview decodes nested figures")
    func overview() async throws {
        let transport = MockTransport(json: """
        {"node":{"id":"n","db_bytes":5},"modules":[{"name":"hc","running":true}],
         "traffic":{"available":true,"rx_total":10,"since":"2026-10-27T10:00:00Z"},
         "healthchecks":{"checks_by_location":{"nbg":2},"nodes":3,"nodes_online":2},
         "account":{"plan":"pro","limits":[{"key":"checks","used":1.5,"max":10,"unlimited":false,"pct":15}]},
         "update":{"version":"2.0"}}
        """)
        let overview = try await Node64.mock(transport).node.overview()
        #expect(overview.node?.dbBytes == 5)
        #expect(overview.traffic?.rxTotal == 10)
        #expect(overview.healthchecks?.checksByLocation?["nbg"] == 2)
        #expect(overview.account?.limits?.first?.pct == 15)
        #expect(overview.update != nil)
    }

    @Test("dashboard layout: get, save, reset")
    func dashboard() async throws {
        let transport = MockTransport(json: #"{"items":[{"id":"node","size":"xl","hidden":false}]}"#)
        let node = Node64.mock(transport).node
        let layout = try await node.dashboardLayout()
        #expect(layout.items?.first?.size == .extraLarge)

        _ = try await node.updateDashboardLayout([.init(id: "link", size: .small, hidden: true)])
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.jsonBody == .object(["items": .array([.object(["id": .string("link"), "size": .string("s"), "hidden": .bool(true)])])]))

        let reset = MockTransport(status: 204, body: Data())
        try await Node64.mock(reset).node.resetDashboardLayout()
        #expect(reset.lastRequest?.nodeRelativePath == "/dashboard/layout")
    }

    @Test("openAPI returns the free-form document")
    func openAPI() async throws {
        let transport = MockTransport(json: #"{"openapi":"3.1.0"}"#)
        let doc = try await Node64.mock(transport).node.openAPI()
        #expect(doc == .object(["openapi": .string("3.1.0")]))
    }

    @Test("Error bodies become Node64Error.api")
    func apiError() async throws {
        let transport = MockTransport(status: 422, json: #"{"error":"Passwort zu kurz"}"#, headers: ["Content-Type": "application/json"])
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).node.createBackup(password: "x")
        }
        guard case .api(let document)? = error else {
            Issue.record("Expected API error")
            return
        }
        #expect(document.status == 422)
    }
}
