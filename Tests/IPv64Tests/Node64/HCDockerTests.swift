import Foundation
import Testing
@testable import IPv64

@Suite("Node64 docker")
struct Node64HCDockerTests {
    @Test("DockerContainers decodes")
    func containers() async throws {
        let transport = MockTransport(json: """
        {"host":"unix:///var/run/docker.sock","socket":true,"system_id":2,"monitored":true,
         "containers":[{"name":"web","kind":"running","health":"healthy","id":"abc","image":"nginx",
         "state":"running","created":"2026-10-27T08:00:00Z","ports":["8080->80/tcp"],
         "check":{"token":"t","name":"web","state":"up","message":"ok"},"key":"docker/web",
         "monitor":"running","bad":false,"as_check":true,"cpu":0.1,"cpus":2,"mem":1000,"max_mem":2000,
         "net_in":1.5,"uptime":60,"restart_count":0,"exit_code":0}]}
        """)
        let result = try await Node64.mock(transport).hc.docker.containers()
        let container = try #require(result.containers?.first)
        #expect(container.kind == .running)
        #expect(container.check?.token == "t")
        #expect(container.maxMem == 2000)
        #expect(result.systemID == 2)
        #expect(transport.lastRequest?.nodeRelativePath == "/healthchecks/docker/containers")
    }

    @Test("Create sends only given fields")
    func create() async throws {
        let transport = MockTransport(status: 201, json: #"{"id":2,"kind":"docker"}"#)
        let system = try await Node64.mock(transport).hc.docker.systems.create(name: "Docker", interval: 30)
        #expect(system.kind == .docker)
        #expect(transport.lastRequest?.jsonBody == .object(["name": .string("Docker"), "interval": .number(30)]))
    }

    @Test("Series and settings requests")
    func seriesAndSettings() async throws {
        let transport = MockTransport(json: #"{"key":"docker/web","step_seconds":60,"points":[{"t":"2026-10-27T08:00:00Z","cpu":1.5,"disk":null}]}"#)
        let api = Node64.mock(transport).hc.docker.systems
        let series = try await api.series(2, key: "docker/web", range: .week)
        #expect(series.points?.first?.cpu == 1.5)
        #expect(transport.lastRequest?.nodeRelativePath == "/healthchecks/docker/systems/2/series?key=docker/web&range=7d")

        _ = try await api.updateSettings(2, key: "docker/web", .init(asCheck: true))
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.nodeRelativePath == "/healthchecks/docker/systems/2/settings?key=docker/web")
        #expect(request.jsonBody == .object(["as_check": .bool(true)]))
    }

    @Test("Delete and reset return on 204")
    func noContent() async throws {
        let transport = MockTransport(status: 204)
        let api = Node64.mock(transport).hc.docker.systems
        try await api.delete(2)
        #expect(transport.lastRequest?.nodeRelativePath == "/healthchecks/docker/systems/2")
        try await api.resetSettings(2)
        #expect(transport.lastRequest?.nodeRelativePath == "/healthchecks/docker/systems/2/settings")
    }

    @Test("Error document becomes Node64Error.api")
    func error() async throws {
        let transport = MockTransport(
            status: 404,
            json: #"{"error":"proxmox system not found"}"#,
            headers: ["Content-Type": "application/json"]
        )
        await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).hc.docker.systems.get(9)
        }
    }
}
