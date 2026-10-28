import Foundation
@testable import IPv64

/// A transport that returns a canned response and records every request.
///
/// `@unchecked Sendable` is sound here: the only mutable state is guarded by `lock`.
final class MockTransport: IPv64Transport, @unchecked Sendable {
    struct Response: Sendable {
        var statusCode: Int
        var body: Data
        var headers: [String: String]
    }

    private let response: Response
    private let lock = NSLock()
    private var recorded: [URLRequest] = []

    init(status: Int = 200, json: String, headers: [String: String] = [:]) {
        var headers = headers
        if headers["Content-Type"] == nil {
            headers["Content-Type"] = status < 400 ? "application/json" : "application/problem+json"
        }
        self.response = Response(statusCode: status, body: Data(json.utf8), headers: headers)
    }

    init(status: Int, body: Data = Data(), headers: [String: String] = [:]) {
        self.response = Response(statusCode: status, body: body, headers: headers)
    }

    /// All requests sent through this transport, in order.
    var requests: [URLRequest] { lock.withLock { recorded } }

    /// The most recent request.
    var lastRequest: URLRequest? { requests.last }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        lock.withLock { recorded.append(request) }
        let httpResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: response.headers
        )!
        return (response.body, httpResponse)
    }
}

extension IPv64 {
    /// A client with a fixed test API key that uses `transport`.
    static func mock(_ transport: MockTransport, actAs: String? = nil) -> IPv64 {
        IPv64(configuration: .init(apiKey: "test-key", actAs: actAs), transport: transport)
    }
}

extension URLRequest {
    /// The decoded JSON body, for assertions.
    var jsonBody: JSONValue? {
        httpBody.flatMap { try? JSONDecoder().decode(JSONValue.self, from: $0) }
    }

    /// Path and query relative to `https://ipv64.net/api/v2`.
    var relativePath: String {
        let string = url?.absoluteString ?? ""
        return string.replacingOccurrences(of: "https://ipv64.net/api/v2", with: "")
    }
}

extension Node64 {
    /// A client for `https://node.example.com/api` with a fixed test API key that uses `transport`.
    static func mock(_ transport: MockTransport, agentActor: String? = nil) -> Node64 {
        Node64(
            configuration: .init(baseURL: URL(string: "https://node.example.com/api")!, apiKey: "node64_test", agentActor: agentActor),
            transport: transport
        )
    }
}

extension URLRequest {
    /// Path and query relative to the mock node `https://node.example.com/api`.
    var nodeRelativePath: String {
        (url?.absoluteString ?? "").replacingOccurrences(of: "https://node.example.com/api", with: "")
    }
}
