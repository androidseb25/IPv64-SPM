import Foundation
import Testing
@testable import IPv64

@Suite("Custom headers and conditional requests")
struct ConditionalRequestTests {
    @Test("Threat feed with ETag returns .notModified on 304")
    func feedNotModified() async throws {
        let transport = MockTransport(status: 304)

        let result = try await IPv64.mock(transport).threat.feed(since: "cursor", ifNoneMatch: "\"abc\"")

        #expect(result == .notModified)
        let request = try #require(transport.lastRequest)
        #expect(request.value(forHTTPHeaderField: "If-None-Match") == "\"abc\"")
        #expect(request.relativePath == "/threat/feed?since=cursor")
    }

    @Test("Threat feed with ETag returns the new data and ETag on 200")
    func feedChanged() async throws {
        let transport = MockTransport(
            json: #"{"data":{"changes":[],"next":"n2","more":false}}"#,
            headers: ["ETag": "\"def\""]
        )

        let result = try await IPv64.mock(transport).threat.feed(since: "cursor", ifNoneMatch: "\"abc\"")

        guard case .changed(let feed, let etag) = result else {
            Issue.record("Expected changed feed, got \(result)")
            return
        }
        #expect(feed.next == "n2")
        #expect(etag == "\"def\"")
    }

    @Test("304 without If-None-Match is still an error")
    func unexpectedNotModified() async throws {
        let transport = MockTransport(status: 304)

        let error = await #expect(throws: IPv64Error.self) {
            try await IPv64.mock(transport).threat.feed()
        }

        #expect(error?.statusCode == 304)
    }

    @Test("Node64 hello sends X-Node64-Node matching the body's node_id")
    func node64HelloHeader() async throws {
        let transport = MockTransport(status: 204)

        try await IPv64.mock(transport).hc2.nodes.hello(Node64HelloInput(nodeID: "node-1"))

        let request = try #require(transport.lastRequest)
        #expect(request.value(forHTTPHeaderField: "X-Node64-Node") == "node-1")
        #expect(request.jsonBody?["node_id"] == "node-1")
    }
}
