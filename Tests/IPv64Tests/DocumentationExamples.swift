import Foundation
import IPv64
import Testing
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Copy-pasteable recipes for integrating the `IPv64` package.
///
/// Every function body is one recipe. The file only uses public API (`import IPv64`, no `@testable`),
/// so it is compiled with the package tests and keeps the documentation honest.
/// Recipes that take an `ipv64` parameter assume the shared client from "Setup".
enum DocumentationExamples {
    enum RecipeError: Error {
        case timedOut
        case cryptoKitUnavailable
    }

    // MARK: - Setup: one shared client

    /// Create the client once and share it; `IPv64` is an immutable `Sendable` class, so no actor is needed.
    static func makeClient() -> IPv64 {
        // Read the key from the environment, or from the Keychain in a real app.
        let apiKey = ProcessInfo.processInfo.environment["IPV64_API_KEY"]
        // `apiKey: nil` is fine for public endpoints such as `threat.ip(_:)`.
        return IPv64(apiKey: apiKey)
        // SwiftUI: keep it in a small `@Observable` model or an `EnvironmentKey` and inject the same instance.
        // Switch the header style with `IPv64(configuration: .init(apiKey: key, authentication: .apiKeyHeader))`.
    }

    // MARK: - DynDNS: update a domain's IP

    /// Set the A and AAAA record of a DynDNS domain (or one prefix) and inspect what happened per address.
    static func updateDynDNS(ipv64: IPv64) async throws {
        // Omit `ipv4`/`ipv6` to use the sender address. `domain` is the domain ID or full name.
        let result = try await ipv64.domains.updateDynDNS(
            "home.ipv64.de",
            ipv4: "203.0.113.10",
            ipv6: "2001:db8::10",
            prefix: "nas"
        )
        print("changed:", result.changed ?? false)
        for entry in result.results ?? [] {
            guard let outcome = entry.result else { continue }
            if outcome == .created || outcome == .updated || outcome == .unchanged {
                print("\(entry.ip ?? "?"): \(outcome)")
            } else {
                // .invalidIP, .cnameConflict, .cdnManaged, .ignored, or a value added by the server later.
                print("\(entry.ip ?? "?") was not applied: \(outcome)")
            }
        }
    }

    // MARK: - DNS records: list, create, update, delete

    /// Manage records; domains take an ID or full name, single records take their numeric ID or their token (both as `String`).
    static func manageRecords(ipv64: IPv64) async throws {
        let domain = "home.ipv64.de"

        let existing = try await ipv64.records.list(domain: domain, type: .a, prefix: "nas")
        print("existing A records:", existing.count)

        let record = try await ipv64.records.create(domain: domain, type: .a, prefix: "nas", content: "203.0.113.10")

        // The token survives IP changes of A/AAAA records, so prefer it over the numeric ID.
        let reference = record.token ?? String(record.id)

        // Changing only the IP keeps ID and token; other changes replace the record (new ID and token).
        let updated = try await ipv64.records.update(reference, content: "203.0.113.11")

        try await ipv64.records.delete(updated.token ?? String(updated.id))

        // Alternative for ACME clients: delete by type, prefix and exact content.
        try await ipv64.records.delete(domain: domain, type: .txt, content: "challenge-value", prefix: "_acme-challenge")
    }

    // MARK: - Create a domain and handle domain_taken / limit_reached

    /// Create a DynDNS domain and react to the two expected business errors.
    static func createDomain(ipv64: IPv64) async throws {
        do {
            let domain = try await ipv64.domains.create(name: "wunschname.ipv64.de")
            print("created domain", domain.id, "update token:", domain.updateToken ?? "-")
        } catch let error as IPv64Error {
            switch (error.statusCode, error.code) {
            case (409, "domain_taken"):
                print("That name is already in use, ask the user for another one.")
            case (403, "limit_reached"):
                print("The plan's domain limit is reached.")
            default:
                throw error
            }
        }
    }

    // MARK: - Classic healthcheck: create, pause, resume, read events

    /// Create a push healthcheck, pause and resume it, then read all events page by page with cursors.
    static func classicHealthcheck(ipv64: IPv64) async throws {
        let check = try await ipv64.healthchecks.create(
            name: "Nightly backup",
            HealthcheckInput(type: .push, periodSeconds: 86_400, graceSeconds: 3_600)
        )
        // Your job pings `check.push?.url`. The token identifies the check in every other call.
        let token = check.token

        _ = try await ipv64.healthchecks.pause(token)
        _ = try await ipv64.healthchecks.resume(token)

        // Without `after` the newest events come first; follow `nextBefore` until there is no further cursor.
        var events: [HealthcheckEvent] = []
        var cursor: Int?
        repeat {
            try Task.checkCancellation()
            let page = try await ipv64.healthchecks.events(token, limit: 100, before: cursor)
            events += page.items
            cursor = page.meta?.hasMore == true ? page.meta?.nextBefore : nil
        } while cursor != nil
        print("loaded \(events.count) events")
    }

    // MARK: - Healthchecks 2.0: HTTP check, list, stats

    /// Create an HTTP check measured from both online locations, list checks and read availability.
    static func healthchecks2(ipv64: IPv64) async throws {
        let input = HC2CheckInput(
            name: "Website",
            type: .http,
            target: "https://example.com/health",
            params: HC2CheckParams(method: "GET", acceptStatus: "200-299"),
            intervalSeconds: 60,
            retries: 2,
            execution: .online,
            locations: [.nuremberg, .falkenstein]
        )
        let created = try await ipv64.hc2.checks.create(input)

        let down = try await ipv64.hc2.checks.list(state: .down)
        print("checks currently down:", down.map(\.token))

        let stats = try await ipv64.hc2.checks.stats(created.token, range: .last7Days)
        print("availability: \(stats.availabilityPercent ?? 0) %")
    }

    // MARK: - Async 202 resources: poll until ready

    /// Generic poller: calls `fetch` until `isDone` holds, honors cancellation and gives up after `maxAttempts`.
    static func poll<Value: Sendable>(
        every interval: Duration = .seconds(2),
        maxAttempts: Int = 30,
        fetch: () async throws -> Value,
        until isDone: (Value) -> Bool
    ) async throws -> Value {
        for attempt in 1...maxAttempts {
            try Task.checkCancellation()
            let value = try await fetch()
            if isDone(value) { return value }
            if attempt < maxAttempts {
                try await Task.sleep(for: interval) // throws CancellationError when the task is cancelled
            }
        }
        throw RecipeError.timedOut
    }

    /// A new Cloud Router and a new CDN domain answer `202 Accepted`; poll `get` until the work is done.
    static func waitForAsyncResources(ipv64: IPv64) async throws {
        // Gateway: ready once `state == .ready` (it starts as `.creating`).
        let router = try await ipv64.cloudRouters.create(name: "Home Lab")
        let gateway = try await ipv64.cloudRouters.createGateway(router: router.id, name: "Frankfurt")
        let readyGateway = try await poll {
            try await ipv64.gateways.get(gateway.id)
        } until: { gateway in
            gateway.state == .ready
        }
        print("gateway ready:", readyGateway.id)

        // CDN: done once `pending` is empty.
        let cdn = try await ipv64.cdn.add(domain: "home.ipv64.de")
        _ = try await poll(every: .seconds(3), maxAttempts: 40) {
            try await ipv64.cdn.get(cdn.id)
        } until: { detail in
            detail.pending?.isEmpty ?? true
        }
    }

    // MARK: - Rate limiting: retry on 429 and 409 with retryAfter

    /// Run `operation`, waiting `problem.retryAfter` seconds and retrying on 429 or a 409 that carries a retry hint.
    static func withRetry<Value: Sendable>(
        maxAttempts: Int = 5,
        sleep: (Duration) async throws -> Void = { try await Task.sleep(for: $0) },
        operation: () async throws -> Value
    ) async throws -> Value {
        var attempt = 1
        while true {
            do {
                return try await operation()
            } catch IPv64Error.api(let problem)
                where attempt < maxAttempts
                && (problem.status == 429 || (problem.status == 409 && problem.retryAfter != nil)) {
                attempt += 1
                try await sleep(.seconds(problem.retryAfter ?? 1))
            }
        }
    }

    /// Usage: e.g. a gateway that is still being set up answers `409 gateway_busy` with `retry_after`.
    static func useRetry(ipv64: IPv64) async throws {
        let peer = try await withRetry {
            try await ipv64.gateways.peers.create(gateway: "gateway-token", name: "Laptop")
        }
        print("created peer", peer.id)
    }

    // MARK: - Acting for another account

    /// Use `actingAs(_:)` to manage an account that shared its administration with you (header `X-IPv64-Act-As`).
    static func actAsOtherAccount(ipv64: IPv64) async throws {
        // Account ID or e-mail address of the other account. The original client is unchanged.
        let customer = ipv64.actingAs("customer@example.com")
        let domains = try await customer.domains.list()
        print("customer has \(domains.count) domains")
    }

    // MARK: - Threat: look up an IP and check a password

    /// Look up an IP on the v64 Blocklist; this works without an API key.
    static func lookUpIP() async throws {
        let anonymous = IPv64(apiKey: nil)
        let info = try await anonymous.threat.ip("198.51.100.23")
        if info.listed == true {
            print("listed with score \(info.score ?? 0), lists:", info.lists?.count ?? 0)
        }
    }

    /// Check a password with k-anonymity: only the first 5 SHA-1 hex characters leave the device.
    static func isPasswordSeenInAttacks(_ password: String, ipv64: IPv64) async throws -> Bool {
        #if canImport(CryptoKit)
        let hash = Insecure.SHA1.hash(data: Data(password.utf8))
            .map { String(format: "%02X", $0) }
            .joined()
        let prefix = String(hash.prefix(5))
        let suffix = String(hash.dropFirst(5))
        let entries = try await ipv64.threat.passwordRangeEntries(prefix: prefix)
        // Count 0 marks padding lines the server adds to hide the real result size.
        return entries.contains { $0.suffix == suffix && $0.count > 0 }
        #else
        throw RecipeError.cryptoKitUnavailable // on Linux use swift-crypto's Insecure.SHA1
        #endif
    }

    // MARK: - Peers: download the WireGuard config

    /// Fetch the WireGuard `.conf` of a peer as text (it contains the private key, treat it as a secret).
    static func downloadWireGuardConfig(ipv64: IPv64) async throws -> String {
        try await ipv64.peers.config("peer-token")
    }

    // MARK: - Error handling pattern

    /// Switch over `IPv64Error` and branch on the machine-readable `code`.
    static func handleErrors(ipv64: IPv64) async {
        do {
            _ = try await ipv64.domains.get("does-not-exist.ipv64.de")
        } catch let error as IPv64Error {
            switch error {
            case .api(let problem):
                switch problem.code {
                case "domain_not_found": print("Unknown domain")
                case "limit_reached": print("Plan limit reached")
                default: print("API error \(problem.status) \(problem.code): \(problem.detail)")
                }
                if let field = problem.field { print("invalid field:", field) }
            case .httpStatus(let code, _):
                print("HTTP \(code) without problem document (proxy, maintenance page)")
            case .missingAPIKey:
                print("Ask the user for an API key")
            case .decoding(let underlying, _):
                print("Unexpected response shape:", underlying)
            case .invalidRequest, .encoding, .invalidResponse:
                print("Programming or transport error:", error.localizedDescription)
            }
        } catch is CancellationError {
            print("cancelled")
        } catch {
            print("network error:", error) // URLError from the transport
        }
    }

    // MARK: - Testing your app code: a stub transport

    /// Returns one canned response for every request; the API wraps payloads in a `{"data": ...}` envelope.
    struct StubTransport: IPv64Transport {
        var status = 200
        var json: String

        func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            guard let url = request.url,
                  let response = HTTPURLResponse(
                    url: url,
                    statusCode: status,
                    httpVersion: "HTTP/1.1",
                    headerFields: ["Content-Type": status < 400 ? "application/json" : "application/problem+json"]
                  )
            else { throw IPv64Error.invalidResponse }
            return (Data(json.utf8), response)
        }
    }

    /// Inject the stub into the client your app code receives, so tests need no network and no API key.
    static func listDomainsWithStub() async throws -> [Domain] {
        let stub = StubTransport(json: #"{"data": [{"id": 1, "name": "home.ipv64.de", "kind": "dyndns"}]}"#)
        let ipv64 = IPv64(apiKey: "test-key", transport: stub)
        return try await ipv64.domains.list()
    }
}

@Suite("Documentation examples")
struct DocumentationExamplesTests {
    actor Counter {
        private(set) var value = 0
        func increment() -> Int {
            value += 1
            return value
        }
    }

    @Test("Stub transport recipe decodes the canned envelope")
    func stubTransport() async throws {
        let domains = try await DocumentationExamples.listDomainsWithStub()
        #expect(domains.count == 1)
        #expect(domains.first?.name == "home.ipv64.de")
        #expect(domains.first?.kind == .dyndns)
    }

    @Test("Stub transport surfaces problem documents as IPv64Error")
    func stubProblem() async {
        let json = #"{"type":"t","title":"Conflict","status":409,"detail":"taken","code":"domain_taken"}"#
        let ipv64 = IPv64(apiKey: "k", transport: DocumentationExamples.StubTransport(status: 409, json: json))
        await #expect(throws: IPv64Error.self) {
            _ = try await ipv64.domains.create(name: "x.ipv64.de")
        }
    }

    @Test("Retry helper retries 429 using retryAfter, then succeeds")
    func retrySucceeds() async throws {
        let calls = Counter()
        let waits = Counter()
        let problem = IPv64Problem(
            type: "t", title: "Too Many Requests", status: 429, detail: "slow down", code: "rate_limited", retryAfter: 0
        )
        let result = try await DocumentationExamples.withRetry(
            sleep: { duration in
                #expect(duration == .seconds(0))
                _ = await waits.increment()
            },
            operation: {
                if await calls.increment() < 3 { throw IPv64Error.api(problem) }
                return "done"
            }
        )
        #expect(result == "done")
        #expect(await calls.value == 3)
        #expect(await waits.value == 2)
    }

    @Test("Retry helper does not retry other errors and gives up after maxAttempts")
    func retryGivesUp() async {
        let calls = Counter()
        let notFound = IPv64Problem(type: "t", title: "Not Found", status: 404, detail: "no", code: "domain_not_found")
        await #expect(throws: IPv64Error.self) {
            try await DocumentationExamples.withRetry(sleep: { _ in }) {
                _ = await calls.increment()
                throw IPv64Error.api(notFound)
            } as Int
        }
        #expect(await calls.value == 1)

        let busy = IPv64Problem(
            type: "t", title: "Conflict", status: 409, detail: "busy", code: "gateway_busy", retryAfter: 1
        )
        await #expect(throws: IPv64Error.self) {
            try await DocumentationExamples.withRetry(maxAttempts: 3, sleep: { _ in }) {
                _ = await calls.increment()
                throw IPv64Error.api(busy)
            } as Int
        }
        #expect(await calls.value == 4)
    }

    @Test("Poller returns once the predicate holds and times out otherwise")
    func polling() async throws {
        let calls = Counter()
        let value = try await DocumentationExamples.poll(every: .milliseconds(1), maxAttempts: 5) {
            await calls.increment()
        } until: { $0 >= 3 }
        #expect(value == 3)

        await #expect(throws: DocumentationExamples.RecipeError.self) {
            try await DocumentationExamples.poll(every: .milliseconds(1), maxAttempts: 2) { 0 } until: { $0 > 0 }
        }
    }
}
