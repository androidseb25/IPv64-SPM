import Foundation
import Testing
@testable import IPv64

@Suite("Node64 ports")
struct Node64PortsTests {
    @Test("Port overview decodes claims and the edge status")
    func decodeOverview() async throws {
        let transport = MockTransport(json: """
        {"ports":[{"owner":"dns64","purpose":"DoH","proto":"tcp","port":443,"bind":"0.0.0.0","active":true,"conflicts":["edge"]}],
         "edge":{"config":{"bind":"","http_port":80,"https_port":443,"public_port":0,"http3":true,"default":"404","default_url":"","default_html":""},
                 "listeners":[{"name":"https","proto":"tcp","port":443,"needed":true,"running":true,"addr":":443"}],
                 "names":[{"name":"node.example.com","path":"/","owner":"web"}]}}
        """)

        let overview = try await Node64.mock(transport).ports.list()

        let claim = try #require(overview.ports?.first)
        #expect(claim.proto == .tcp)
        #expect(claim.conflicts == ["edge"])
        #expect(overview.edge?.config?.httpsPort == 443)
        #expect(overview.edge?.config?.defaultResponse == .notFound)
        #expect(overview.edge?.listeners?.first?.name == .https)
        #expect(overview.edge?.names?.first?.owner == "web")
        #expect(transport.lastRequest?.nodeRelativePath == "/ports")
    }

    @Test("Probe sends proto, port and bind as query")
    func probe() async throws {
        let transport = MockTransport(json: #"{"free":false,"used_by":"dns64","purpose":"DoH"}"#)

        let result = try await Node64.mock(transport).ports.probe(port: 53, transport: .udp, bind: "127.0.0.1")

        #expect(result.free == false)
        #expect(result.usedBy == "dns64")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.nodeRelativePath == "/ports/probe?proto=udp&port=53&bind=127.0.0.1")
    }

    @Test("Edge get and update sends only the given fields")
    func edgeUpdate() async throws {
        let transport = MockTransport(json: #"{"config":{"http_port":8080}}"#)

        let current = try await Node64.mock(transport).ports.edge.get()
        #expect(current.config?.httpPort == 8080)
        #expect(transport.lastRequest?.httpMethod == "GET")
        #expect(transport.lastRequest?.nodeRelativePath == "/edge")

        let status = try await Node64.mock(transport).ports.edge.update(
            .init(httpPort: 8080, http3: false, defaultResponse: .redirect, defaultURL: "https://example.com")
        )

        #expect(status.config?.httpPort == 8080)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.nodeRelativePath == "/edge")
        #expect(request.jsonBody == .object([
            "http_port": .number(8080), "http3": .bool(false),
            "default": .string("redirect"), "default_url": .string("https://example.com"),
        ]))
    }

    @Test("Edge UI decodes and updates")
    func edgeUI() async throws {
        let transport = MockTransport(json: #"{"name":"node.home.arpa","public":false,"cert":"auto","cert_from_env":false}"#)
        let node = Node64.mock(transport)

        let ui = try await node.ports.edge.ui()
        #expect(ui.isPublic == false)
        #expect(ui.cert == "auto")
        #expect(transport.lastRequest?.nodeRelativePath == "/edge/ui")

        _ = try await node.ports.edge.updateUI(name: "", isPublic: true)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "PUT")
        #expect(request.jsonBody == .object(["name": .string(""), "public": .bool(true)]))
    }

    @Test("Error documents become Node64Error.api")
    func error() async throws {
        let transport = MockTransport(status: 422, json: #"{"error":"Port ungültig","field":"https_port"}"#)

        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).ports.edge.update(.init(httpsPort: 99_999))
        }

        guard case .api(let document) = error else {
            Issue.record("Expected an API error")
            return
        }
        #expect(document.status == 422)
        #expect(document.field == "https_port")
    }
}
