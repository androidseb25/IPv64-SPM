import Foundation
import Testing
@testable import IPv64

@Suite("Node64 proxmox")
struct Node64HCProxmoxTests {
    static let systemJSON = """
    {"id":1,"kind":"pve","name":"pve1","addresses":["https://pve1.lan:8006"],"token_id":"node64@pve!monitor",
     "pin_sha256":"","interval":30,"enabled":true,"created":"2026-10-27T08:00:00Z","uid":"u","has_secret":true,
     "state":"ok","version":"8.2","cluster":"c","quorate":true,"address":"https://pve1.lan:8006",
     "last_poll":"2026-10-27T09:00:00Z","nodes":1,"nodes_online":1,"guests":3,"guests_running":2,"guests_bad":0}
    """

    @Test("PVESystem decodes and list sends kind")
    func list() async throws {
        let transport = MockTransport(json: "[\(Self.systemJSON)]")
        let systems = try await Node64.mock(transport).hc.proxmox.systems.list(kind: .all)
        let system = try #require(systems.first)
        #expect(system.state == .ok)
        #expect(system.tokenID == "node64@pve!monitor")
        #expect(system.guestsRunning == 2)
        #expect(transport.lastRequest?.nodeRelativePath == "/healthchecks/proxmox/systems?kind=all")
    }

    @Test("Resources decode")
    func resources() async throws {
        let transport = MockTransport(json: """
        {"system":\(Self.systemJSON),"resources":[{"key":"qemu/101","type":"qemu","node":"pve1","vmid":101,
        "name":"vm","state":"running","tags":["a"],"cpu":0.2,"max_cpu":4,"mem":10,"max_mem":20,"uptime":5,
        "labels":{"k":"v"},"created":1790000000,"health":"healthy","detail":"oom"}]}
        """)
        let result = try await Node64.mock(transport).hc.proxmox.systems.resources(1)
        let resource = try #require(result.resources?.first)
        #expect(resource.type == .qemu)
        #expect(resource.maxCPU == 4)
        #expect(resource.labels?["k"] == "v")
        #expect(resource.health == .healthy)
        #expect(result.system?.id == 1)
    }

    @Test("Probe merges system_id into the body and decodes the result")
    func probe() async throws {
        let transport = MockTransport(json: """
        {"ok":true,"version":"8.2","nodes":["pve1"],"guests":3,"cert_sha256":"ab","cert_trusted":false,"perm_warning":"w"}
        """)
        let input = Node64.PVESystemInput(addresses: ["https://pve1.lan:8006"], tokenID: "t")
        let probe = try await Node64.mock(transport).hc.proxmox.probe(input, systemID: 1)
        #expect(probe.certTrusted == false)
        #expect(probe.certSHA256 == "ab")
        let request = try #require(transport.lastRequest)
        #expect(request.nodeRelativePath == "/healthchecks/proxmox/probe")
        #expect(request.jsonBody == .object([
            "addresses": .array([.string("https://pve1.lan:8006")]),
            "token_id": .string("t"),
            "system_id": .number(1),
        ]))
    }

    @Test("Create and update send the system input")
    func createUpdate() async throws {
        let transport = MockTransport(json: Self.systemJSON)
        let api = Node64.mock(transport).hc.proxmox.systems
        _ = try await api.create(.init(name: "pve1", tokenID: "t", secret: "s", enabled: true))
        #expect(transport.lastRequest?.jsonBody == .object([
            "name": .string("pve1"), "token_id": .string("t"), "secret": .string("s"), "enabled": .bool(true),
        ]))
        _ = try await api.update(1, .init(enabled: false))
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.nodeRelativePath == "/healthchecks/proxmox/systems/1")
    }

    @Test("Settings decode and expect_running null is encoded explicitly")
    func settings() async throws {
        let transport = MockTransport(json: """
        {"system_id":1,"items":{"qemu/101":{"system_id":1,"key":"qemu/101","muted":true,"expect_running":null,
        "rules":{"stopped":true,"cpu":{"percent":90,"minutes":5},"channels":[1,2]}}},
        "effective":{"":{"delay":2,"channels":[]}},"defaults":{}}
        """)
        let api = Node64.mock(transport).hc.proxmox.systems
        let overview = try await api.settings(1)
        let item = try #require(overview.items?["qemu/101"])
        #expect(item.rules?.cpu?.percent == 90)
        #expect(item.rules?.channels == [1, 2])
        #expect(item.expectRunning == nil)
        #expect(overview.effective?[""]?["delay"]?.intValue == 2)

        _ = try await api.updateSettings(1, key: "qemu/101", .init(expectRunning: .automatic, rules: .init(delay: 3)))
        let request = try #require(transport.lastRequest)
        #expect(request.nodeRelativePath == "/healthchecks/proxmox/systems/1/settings?key=qemu/101")
        #expect(request.jsonBody == .object([
            "expect_running": .null,
            "rules": .object(["delay": .number(3)]),
        ]))
    }

    @Test("Series sends key and range with percent-encoding")
    func series() async throws {
        let transport = MockTransport(json: #"{"key":"node/pve 1","range":"1h","step_seconds":60,"points":[]}"#)
        let series = try await Node64.mock(transport).hc.proxmox.systems.series(1, key: "node/pve 1", range: .hour)
        #expect(series.stepSeconds == 60)
        let path = try #require(transport.lastRequest?.nodeRelativePath)
        #expect(path.hasPrefix("/healthchecks/proxmox/systems/1/series?"))
        #expect(path.contains("range=1h"))
        #expect(path.contains("key=node/pve%201") || path.contains("key=node%2Fpve%201"))
    }

    @Test("Delete returns on 204 and errors map to Node64Error")
    func deleteAndError() async throws {
        let ok = MockTransport(status: 204)
        try await Node64.mock(ok).hc.proxmox.systems.delete(1)
        #expect(ok.lastRequest?.httpMethod == "DELETE")

        let failing = MockTransport(
            status: 422,
            json: #"{"error":"invalid","field":"interval","key":"x"}"#,
            headers: ["Content-Type": "application/json"]
        )
        await #expect(throws: Node64Error.self) {
            try await Node64.mock(failing).hc.proxmox.systems.update(1, .init(interval: 1))
        }
    }
}
