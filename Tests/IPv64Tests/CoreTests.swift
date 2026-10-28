import Foundation
import Testing
@testable import IPv64

@Suite("Core")
struct CoreTests {
    @Test("Bearer authentication is the default")
    func bearerAuthentication() async throws {
        let transport = MockTransport(json: #"{"data":{"status":"ok"}}"#)
        let client = IPv64(apiKey: "secret", transport: transport)

        _ = try await client.send(Request(.get, "/health"), as: APIHealth.self)

        let request = try #require(transport.lastRequest)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
        #expect(request.value(forHTTPHeaderField: "X-API-Key") == nil)
        #expect(request.value(forHTTPHeaderField: "User-Agent") == "IPv64-Swift/2.0")
    }

    @Test("X-API-Key authentication sends the key in its own header")
    func apiKeyHeaderAuthentication() async throws {
        let transport = MockTransport(json: #"{"data":{"status":"ok"}}"#)
        let client = IPv64(configuration: .init(apiKey: "secret", authentication: .apiKeyHeader), transport: transport)

        _ = try await client.send(Request(.get, "/health"), as: APIHealth.self)

        let request = try #require(transport.lastRequest)
        #expect(request.value(forHTTPHeaderField: "X-API-Key") == "secret")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("Required authentication without an API key fails before sending")
    func missingAPIKey() async throws {
        let transport = MockTransport(json: #"{"data":{}}"#)
        let client = IPv64(apiKey: nil, transport: transport)

        await #expect {
            try await client.send(Request(.get, "/me"), as: JSONValue.self)
        } throws: { error in
            guard case IPv64Error.missingAPIKey = error else { return false }
            return true
        }
        #expect(transport.requests.isEmpty)
    }

    @Test(
        "Authorization modes decide whether the API key and X-IPv64-Act-As are sent",
        arguments: [
            (Authorization.required, "secret" as String?, true),
            (.optional, "secret", true),
            (.optional, nil, false),
            (.none, "secret", false),
            (.none, nil, false),
        ]
    )
    func authorizationModes(authorization: Authorization, apiKey: String?, sendsKey: Bool) throws {
        let configuration = IPv64.Configuration(apiKey: apiKey, actAs: "kunde@example.com")
        let client = IPv64(configuration: configuration, transport: MockTransport(json: "{}"))

        let request = try client.makeURLRequest(for: Request(.get, "/x", authorization: authorization))

        #expect((request.value(forHTTPHeaderField: "Authorization") != nil) == sendsKey)
        if sendsKey {
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret")
        }
        let sendsActAs = authorization != .none
        #expect((request.value(forHTTPHeaderField: "X-IPv64-Act-As") != nil) == sendsActAs)
    }

    @Test("actingAs(_:) sends X-IPv64-Act-As and keeps the original client unchanged")
    func actingAs() async throws {
        let transport = MockTransport(json: #"{"data":{}}"#)
        let client = IPv64.mock(transport)

        _ = try await client.actingAs("kunde@example.com").send(Request(.get, "/me"), as: JSONValue.self)
        _ = try await client.send(Request(.get, "/me"), as: JSONValue.self)

        #expect(transport.requests[0].value(forHTTPHeaderField: "X-IPv64-Act-As") == "kunde@example.com")
        #expect(transport.requests[1].value(forHTTPHeaderField: "X-IPv64-Act-As") == nil)
        #expect(client.configuration.actAs == nil)
    }

    @Test("Interpolated path segments are percent-encoded")
    func pathEncoding() throws {
        let client = IPv64.mock(MockTransport(json: "{}"))
        let ip = "2001:db8::1"
        let odd = "a/b?c#d e"

        let request = try client.makeURLRequest(for: Request(.get, "/threat/ip/\(ip)/x/\(odd)"))

        #expect(request.url?.absoluteString == "https://ipv64.net/api/v2/threat/ip/2001:db8::1/x/a%2Fb%3Fc%23d%20e")
    }

    @Test("Nil query items are dropped and '+' is encoded")
    func queryEncoding() throws {
        let client = IPv64.mock(MockTransport(json: "{}"))
        let missing: Int? = nil
        let since = Date(timeIntervalSince1970: 1_791_626_400)

        let request = try client.makeURLRequest(for: Request(
            .get, "/me/logs",
            query: [QueryItem("limit", 50), QueryItem("before", missing), QueryItem("since", since), QueryItem("q", "a+b")]
        ))

        #expect(request.relativePath == "/me/logs?limit=50&since=2026-10-10T10:00:00Z&q=a%2Bb")
    }

    @Test("Open enums, booleans and reserved characters are encoded as query values")
    func queryValueKinds() throws {
        let client = IPv64.mock(MockTransport(json: "{}"))
        let family: IPFamily? = .ipv6
        let missingFamily: IPFamily? = nil

        let request = try client.makeURLRequest(for: Request(
            .get, "/x",
            query: [
                QueryItem("family", family), QueryItem("other", missingFamily),
                QueryItem("flag", false), QueryItem("content", "a&b=c d"),
            ]
        ))

        #expect(request.relativePath == "/x?family=ipv6&flag=false&content=a%26b%3Dc%20d")
    }

    @Test("A trailing slash in the base URL is ignored")
    func baseURLTrailingSlash() throws {
        let baseURL = try #require(URL(string: "https://example.com/api/v2/"))
        let configuration = IPv64.Configuration(apiKey: "k", baseURL: baseURL)
        let client = IPv64(configuration: configuration, transport: MockTransport(json: "{}"))

        let request = try client.makeURLRequest(for: Request(.get, "/me"))

        #expect(request.url?.absoluteString == "https://example.com/api/v2/me")
    }

    @Test("Cancelling the calling task cancels the request and surfaces CancellationError")
    func cancellation() async throws {
        struct SuspendingTransport: IPv64Transport {
            func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
                try await Task.sleep(for: .seconds(60))
                throw IPv64Error.invalidResponse
            }
        }
        let client = IPv64(apiKey: "k", transport: SuspendingTransport())

        let task = Task { try await client.meta.health() }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test("Problem documents are thrown as IPv64Error.api")
    func problemDocument() async throws {
        let transport = MockTransport(status: 404, json: """
        {"type":"https://ipv64.net/api/v2/errors#domain_not_found","title":"Not Found","status":404,"detail":"Domain 'x' not found.","code":"domain_not_found"}
        """)

        let error = await #expect(throws: IPv64Error.self) {
            try await IPv64.mock(transport).send(Request(.get, "/domains/x"), as: JSONValue.self)
        }

        #expect(error?.statusCode == 404)
        #expect(error?.code == "domain_not_found")
        #expect(error?.errorDescription == "Domain 'x' not found.")
    }

    @Test("Retry-After header fills retryAfter on 429")
    func retryAfterHeader() async throws {
        let transport = MockTransport(
            status: 429,
            json: #"{"type":"t","title":"Too Many Requests","status":429,"detail":"Too many requests.","code":"rate_limited"}"#,
            headers: ["Retry-After": "3"]
        )

        let error = await #expect(throws: IPv64Error.self) {
            try await IPv64.mock(transport).send(Request(.get, "/me"), as: JSONValue.self)
        }

        guard case .api(let problem) = error else {
            Issue.record("Expected an API problem, got \(String(describing: error))")
            return
        }
        #expect(problem.retryAfter == 3)
    }

    @Test("Error status without a problem document becomes httpStatus")
    func plainErrorStatus() async throws {
        let transport = MockTransport(status: 502, body: Data("Bad Gateway".utf8))

        let error = await #expect(throws: IPv64Error.self) {
            try await IPv64.mock(transport).send(Request(.get, "/me"), as: JSONValue.self)
        }

        #expect(error?.statusCode == 502)
        #expect(error?.code == nil)
    }

    @Test("Undecodable bodies throw IPv64Error.decoding with the raw body")
    func decodingError() async throws {
        let transport = MockTransport(json: #"{"data":{"status":42}}"#)

        let error = await #expect(throws: IPv64Error.self) {
            try await IPv64.mock(transport).send(Request(.get, "/health"), as: APIHealth.self)
        }

        guard case .decoding(_, let body) = error else {
            Issue.record("Expected a decoding error, got \(String(describing: error))")
            return
        }
        #expect(String(data: body, encoding: .utf8)?.contains("42") == true)
    }

    @Test("JSON bodies set Content-Type and encode dates as ISO 8601", arguments: [HTTPMethod.post, .patch, .put])
    func jsonBody(method: HTTPMethod) throws {
        struct Body: Encodable, Sendable {
            let name: String
            let at: Date
        }
        let client = IPv64.mock(MockTransport(json: "{}"))

        let request = try client.makeURLRequest(for: Request(
            method, "/x",
            body: .json(Body(name: "n", at: Date(timeIntervalSince1970: 1_791_626_400)))
        ))

        #expect(request.httpMethod == method.rawValue)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(request.jsonBody == ["name": "n", "at": "2026-10-10T10:00:00Z"])
    }

    @Test(
        "Timestamps decode with offset, fractional seconds and as plain dates",
        arguments: [
            ("2026-10-10T12:00:00+02:00", 1_791_626_400.0),
            ("2026-10-10T10:00:00Z", 1_791_626_400.0),
            ("2026-10-10T10:00:00.500Z", 1_791_626_400.5),
            ("2026-10-10", 1_791_590_400.0),
        ]
    )
    func dateDecoding(string: String, expected: TimeInterval) throws {
        let date = try #require(IPv64Coding.date(from: string))
        #expect(date.timeIntervalSince1970 == expected)
    }

    @Test("Open enums keep unknown server values")
    func openEnumUnknownValue() throws {
        let data = Data(#"["ipv4","ipv5"]"#.utf8)

        let families = try JSONDecoder().decode([IPFamily].self, from: data)

        #expect(families == [.ipv4, IPFamily(rawValue: "ipv5")])
        #expect(try String(data: JSONEncoder().encode(families), encoding: .utf8) == #"["ipv4","ipv5"]"#)
    }

    @Test("JSONValue round-trips arbitrary JSON")
    func jsonValueRoundTrip() throws {
        let value: JSONValue = ["a": 1, "b": [true, nil, "x"], "c": ["d": 1.5]]

        let decoded = try JSONDecoder().decode(JSONValue.self, from: JSONEncoder().encode(value))

        #expect(decoded == value)
        #expect(decoded["a"]?.intValue == 1)
        #expect(decoded["c"]?["d"]?.doubleValue == 1.5)
    }

    @Test("Multipart bodies contain fields and files")
    func multipart() {
        var form = MultipartFormData(boundary: "B")
        form.append("hello", name: "text")
        form.append(Data([0x01, 0x02]), name: "icon", filename: "logo.png", contentType: "image/png")

        let body = form.encoded()
        let expected = Data("--B\r\nContent-Disposition: form-data; name=\"text\"\r\n\r\nhello\r\n--B\r\nContent-Disposition: form-data; name=\"icon\"; filename=\"logo.png\"\r\nContent-Type: image/png\r\n\r\n".utf8)
            + Data([0x01, 0x02])
            + Data("\r\n--B--\r\n".utf8)

        #expect(body == expected)
        #expect(form.contentType == "multipart/form-data; boundary=B")
    }
}
