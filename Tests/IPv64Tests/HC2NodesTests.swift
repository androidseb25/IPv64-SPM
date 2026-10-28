import Foundation
import Testing
@testable import IPv64

@Suite("HC2 Nodes")
struct HC2NodesTests {
    static let nodeJSON = """
    {"node_id":"n123","name":"Home","location":"Berlin","version":"1.2","timezone":"Europe/Berlin","modules":["hc"],"remote_mgmt":"full","online":true,
    "last_seen":"2026-10-10T12:00:00+02:00","last_sync":null,"outbox_size":0,"conflicts":1,"hub":"hub1","linked_at":"2026-10-01T12:00:00+02:00"}
    """

    @Test("Node and flattened NodeDetail decode")
    func decode() async throws {
        let node = try await IPv64.mock(MockTransport(json: #"{"data":[\#(Self.nodeJSON)]}"#)).hc2.nodes.list().first
        #expect(node?.id == "n123")
        #expect(node?.remoteMgmt == .full)
        #expect(node?.lastSync == nil)

        let detailJSON = Self.nodeJSON.dropLast() + #","checks":[{"token":"t","name":"c"}]}"#
        let transport = MockTransport(json: #"{"data":\#(detailJSON)}"#)
        let detail = try await IPv64.mock(transport).hc2.nodes.get("n123")
        #expect(detail.checks?.first?.token == "t")
        #expect(detail.conflicts == 1)
        #expect(transport.lastRequest?.relativePath == "/hc2/nodes/n123")
    }

    @Test("Link, update and unlink bodies")
    func bodies() async throws {
        let link = MockTransport(status: 202, json: #"{"data":{"accepted":true,"detail":"d"}}"#)
        let linked = try await IPv64.mock(link).hc2.nodes.link(code: "ABCD-EFGH", remoteManagement: .read)
        #expect(linked.accepted == true)
        #expect(link.lastRequest?.jsonBody == ["code": "ABCD-EFGH", "remote_mgmt": "read"])

        let patch = MockTransport(json: #"{"data":{"node_id":"n123"}}"#)
        _ = try await IPv64.mock(patch).hc2.nodes.update("n123", name: "New")
        #expect(patch.lastRequest?.httpMethod == "PATCH")
        #expect(patch.lastRequest?.jsonBody == ["name": "New"])

        let unlink = MockTransport(json: #"{"data":{"unlinked":true,"checks_kept_online":2,"checks_deleted":1}}"#)
        let result = try await IPv64.mock(unlink).hc2.nodes.unlink("n123", keepChecks: false)
        #expect(result.checksKeptOnline == 2)
        #expect(unlink.lastRequest?.httpMethod == "DELETE")
        #expect(unlink.lastRequest?.jsonBody == ["keep_checks": false])
    }

    @Test("Commands")
    func commands() async throws {
        let list = MockTransport(json: """
        {"data":[{"command_id":1,"node_id":"n123","name":"run_check","args":{"token":"t"},"created_at":"2026-10-10T12:00:00+02:00","done_at":null,"ok":true,"output":"fine"}]}
        """)
        let commands = try await IPv64.mock(list).hc2.nodes.commands("n123", limit: 10)
        #expect(commands.first?.id == 1)
        #expect(commands.first?.output == "fine")
        #expect(list.lastRequest?.relativePath == "/hc2/nodes/n123/commands?limit=10")

        let post = MockTransport(status: 202, json: #"{"data":{"command_id":2,"name":"resolve_conflict"}}"#)
        let sent = try await IPv64.mock(post).hc2.nodes.sendCommand(
            "n123", name: .resolveConflict, arguments: .init(id: 4, keep: .server)
        )
        #expect(sent.commandID == 2)
        #expect(post.lastRequest?.jsonBody == ["name": "resolve_conflict", "args": ["id": 4, "keep": "server"]])
    }

    @Test("Node64 hello and container overview")
    func node64() async throws {
        let hello = MockTransport(status: 200, body: Data())
        try await IPv64.mock(hello).hc2.nodes.hello(
            Node64HelloInput(nodeID: "n123", osArch: "linux/amd64", modules: ["dyndns"], features: .init(hcSyncLinked: true, dyndns: true))
        )
        #expect(hello.lastRequest?.relativePath == "/node64/hello")
        #expect(hello.lastRequest?.value(forHTTPHeaderField: "X-Node64-Node") == "n123")
        #expect(hello.lastRequest?.jsonBody == [
            "node_id": "n123", "os_arch": "linux/amd64", "modules": ["dyndns"],
            "features": ["hc_sync_linked": true, "dyndns": true],
        ])

        let empty = MockTransport(status: 200, body: Data())
        #expect(try await IPv64.mock(empty).hc2.nodes.containers() == .null)
        let some = MockTransport(json: #"{"data":[{"node_id":"x"}]}"#)
        #expect(try await IPv64.mock(some).hc2.nodes.containers()["data"] != nil)
        #expect(some.lastRequest?.relativePath == "/node64/nodes")
    }

    @Test("403 node_removed becomes IPv64Error.api")
    func removed() async throws {
        let transport = MockTransport(status: 403, json: #"{"type":"about:blank","title":"Forbidden","status":403,"code":"node_removed","detail":"removed"}"#)
        do {
            try await IPv64.mock(transport).hc2.nodes.hello(Node64HelloInput(nodeID: "n"))
            Issue.record("expected an error")
        } catch let IPv64Error.api(problem) {
            #expect(problem.code == "node_removed")
        }
    }
}
