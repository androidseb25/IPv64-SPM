import Foundation
import Testing
@testable import IPv64

@Suite("Node64 healthchecks: direct methods")
struct Node64HCTests {
    @Test("Push without payload is an unauthenticated GET")
    func pushGet() async throws {
        let transport = MockTransport(json: #"{"status":"ok"}"#)
        let result = try await Node64.mock(transport).hc.push("tok", status: .down, message: "a b")
        #expect(result.status == "ok")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "GET")
        #expect(request.nodeRelativePath == "/push/tok?status=down&msg=a%20b")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("Push with payload is a POST with the given content type")
    func pushPost() async throws {
        let transport = MockTransport(json: #"{"status":"ok"}"#)
        try await Node64.mock(transport).hc.push("tok", payload: Data("hello".utf8), contentType: "text/plain")
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.nodeRelativePath == "/push/tok")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "text/plain")
        #expect(request.httpBody == Data("hello".utf8))
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("Push 429 without body is an API error")
    func pushRateLimited() async throws {
        let transport = MockTransport(status: 429, body: Data())
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).hc.push("tok")
        }
        #expect(error?.statusCode == 429)
    }

    @Test("Check types accept strings, objects and a wrapped list")
    func checkTypes() async throws {
        let strings = MockTransport(json: #"["http","push"]"#)
        #expect(try await Node64.mock(strings).hc.checks.types() == [.http, .push])
        #expect(strings.lastRequest?.nodeRelativePath == "/check-types")
        let objects = MockTransport(json: #"[{"type":"dns"},{"name":"tcp"}]"#)
        #expect(try await Node64.mock(objects).hc.checks.types() == [.dns, .tcp])
        let wrapped = MockTransport(json: #"{"types":["icmp"]}"#)
        #expect(try await Node64.mock(wrapped).hc.checks.types() == [.icmp])
    }

    @Test("Check types reject an unexpected shape instead of returning an empty list")
    func checkTypesUnexpectedShape() async throws {
        let transport = MockTransport(json: #"{"http":"HTTP"}"#)
        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).hc.checks.types()
        }
        guard case .decoding? = error else {
            Issue.record("Expected a decoding error, got \(String(describing: error))")
            return
        }
    }

    @Test("Open enums keep unknown values")
    func openEnums() throws {
        let type = try JSONDecoder().decode(Node64.CheckType.self, from: Data(#""quic""#.utf8))
        #expect(type.rawValue == "quic")
        #expect(Node64.CheckOwner.thisNode.rawValue == "self")
    }
}
