import Foundation
import Testing
@testable import IPv64

@Suite("Node64 cluster")
struct Node64ClusterTests {
    @Test("ClusterGroup decodes members and sync modules")
    func decodeGroup() async throws {
        let transport = MockTransport(json: """
        {"account_id":1,"linked":true,"forwarder":"n1","forwarder_self":false,"code":"ABC","code_expires":"2026-10-27T10:10:00Z",
         "members":[{"node_id":"n2","name":"Two","url":"https://two","online":true,"state":"suspended","reason":"tls_binding","sync":null,"last_seen":"2026-10-27T10:00:00Z"}],
         "sync_modules":[{"id":"healthchecks","available":true,"enabled":true,"items":[{"id":"checks","title_key":"t","enabled":false}]}],
         "https_port":0}
        """)
        let group = try await Node64.mock(transport).cluster.group()
        #expect(group.members?.first?.id == "n2")
        #expect(group.members?.first?.state == .suspended)
        #expect(group.members?.first?.reason == .tlsBinding)
        #expect(group.members?.first?.sync == nil)
        #expect(group.syncModules?.first?.items?.first?.enabled == false)
        #expect(group.httpsPort == 0)
        #expect(transport.lastRequest?.nodeRelativePath == "/group")
    }

    @Test("Code creation and discarding")
    func codes() async throws {
        let created = MockTransport(status: 201, json: #"{"code":"XYZ","expires":"2026-10-27T10:10:00Z"}"#)
        let code = try await Node64.mock(created).cluster.createCode()
        #expect(code.code == "XYZ")
        #expect(created.lastRequest?.httpMethod == "POST")

        let discarded = MockTransport(status: 204, body: Data())
        try await Node64.mock(discarded).cluster.discardCode()
        #expect(discarded.lastRequest?.httpMethod == "DELETE")
        #expect(discarded.lastRequest?.nodeRelativePath == "/group/code")
    }

    @Test("join sends addr, code and self_url")
    func join() async throws {
        let transport = MockTransport(json: #"{"account_id":1,"members":[]}"#)
        _ = try await Node64.mock(transport).cluster.join(address: "https://a", code: "C", selfURL: "https://me")
        #expect(transport.lastRequest?.jsonBody == .object(["addr": .string("https://a"), "code": .string("C"), "self_url": .string("https://me")]))
    }

    @Test("Member calls percent-encode the ID")
    func members() async throws {
        let transport = MockTransport(status: 204, body: Data())
        let cluster = Node64.mock(transport).cluster
        try await cluster.updateMember("a/b", url: "https://x")
        #expect(transport.lastRequest?.nodeRelativePath == "/group/members/a%2Fb")
        #expect(transport.lastRequest?.jsonBody == .object(["url": .string("https://x")]))
        try await cluster.removeMember("n2")
        #expect(transport.lastRequest?.httpMethod == "DELETE")
        try await cluster.resumeMember("n2")
        #expect(transport.lastRequest?.nodeRelativePath == "/group/members/n2/resume")
        try await cluster.leave()
        #expect(transport.lastRequest?.nodeRelativePath == "/group/leave")
    }

    @Test("setSync sends module, item and enabled")
    func sync() async throws {
        let transport = MockTransport(json: #"{"sync_modules":[{"id":"certs","enabled":true}]}"#)
        let state = try await Node64.mock(transport).cluster.setSync(module: "certs", item: "certificates", enabled: true)
        #expect(state.syncModules?.first?.id == "certs")
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.jsonBody == .object(["module": .string("certs"), "item": .string("certificates"), "enabled": .bool(true)]))
    }

    @Test("A 409 on resume becomes Node64Error.api")
    func apiError() async throws {
        let transport = MockTransport(status: 409, json: #"{"error":"bleibt ausgesetzt"}"#, headers: ["Content-Type": "application/json"])
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).cluster.resumeMember("n2")
        }
        #expect(error?.statusCode == 409)
    }
}
