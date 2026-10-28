import Foundation
import Testing
import IPv64

/// Node64 recipes from `AGENTS.md`. They compile against the public API only;
/// the ones that need no real node also run in the suite below.
enum Node64DocumentationExamples {
    // MARK: - Setup: one client per node

    /// Create one client per node and share it; `Node64` is an immutable `Sendable` class.
    static func makeNodeClient() throws -> Node64 {
        guard let baseURL = URL(string: "https://node.example.com/api") else {
            throw Node64Error.invalidRequest("Invalid node URL")
        }
        // API key from the node's settings (Einstellungen > API-Keys), e.g. from the Keychain.
        let apiKey = ProcessInfo.processInfo.environment["NODE64_API_KEY"]
        // `agentActor` is the name shown in the node's audit log for changes made by this app.
        return Node64(configuration: .init(baseURL: baseURL, apiKey: apiKey, agentActor: "My App"))
    }

    // MARK: - Healthchecks: find down checks and pause one

    static func pauseDownChecks(node64: Node64) async throws {
        let down = try await node64.hc.checks.list(state: .down)
        for check in down {
            print("\(check.name ?? check.token) is down")
        }
        if let first = down.first {
            let paused = try await node64.hc.checks.pause(first.token)
            print("paused", paused.token)
        }
    }

    // MARK: - Healthchecks: create and safely update a check

    /// `PUT /checks/{token}` always takes name, type and target and clears a missing
    /// description, so build the update from the current check.
    static func createAndUpdateCheck(node64: Node64) async throws {
        let input = Node64.CheckInput(
            name: "Website",
            type: .http,
            target: "https://example.com/health",
            intervalSeconds: 60
        )
        // The spec documents no response body for create/update, so they return raw JSON.
        let created = try await node64.hc.checks.create(input)
        guard let token = created["token"]?.stringValue else { return }

        let current = try await node64.hc.checks.get(token)
        var update = Node64.CheckInput(
            name: current.name ?? "Website",
            type: current.type ?? .http,
            target: current.target
        )
        update.description = current.description // keep it, nil would clear it
        update.intervalSeconds = 30
        _ = try await node64.hc.checks.update(token, update)
    }

    // MARK: - Push heartbeat from a script

    /// Push endpoints need no API key; the check token authorizes the heartbeat.
    static func sendHeartbeat(checkToken: String, backupFailed: Bool) async throws {
        guard let baseURL = URL(string: "https://node.example.com/api") else { return }
        let anonymous = Node64(baseURL: baseURL, apiKey: nil)
        _ = try await anonymous.hc.push(
            checkToken,
            status: backupFailed ? .down : .up,
            message: backupFailed ? "Backup failed" : nil
        )
    }

    // MARK: - Events: page with the `before` cursor

    /// Event lists are plain arrays; pass the last event's `id` as `before` for older entries.
    static func loadAllEvents(node64: Node64, checkToken: String) async throws -> [Node64.CheckEvent] {
        var events: [Node64.CheckEvent] = []
        var before: Int?
        while true {
            try Task.checkCancellation()
            let page = try await node64.hc.checks.events(checkToken, limit: 100, before: before)
            events += page
            guard page.count == 100, let last = page.last else { break }
            before = last.id
        }
        return events
    }

    // MARK: - DynDNS: trigger an update round

    static func runDynDNSCheck(node64: Node64) async throws {
        switch try await node64.dyndns.check() {
        case .completed(let status):
            print("IPv4:", status.ipv4 ?? "-", "IPv6:", status.ipv6 ?? "-")
        case .running:
            // Still running after 45 s: read the result later.
            let status = try await node64.dyndns.status()
            print("current IPv4:", status.ipv4 ?? "-")
        }
    }

    // MARK: - Backup: download the database

    /// The SQLite database contains all secrets of the node; store it encrypted.
    static func downloadBackup(node64: Node64, to url: URL) async throws {
        let database = try await node64.node.downloadDatabase()
        try database.write(to: url, options: [.atomic, .completeFileProtection])
    }

    // MARK: - Error handling

    static func handleErrors(node64: Node64) async throws {
        do {
            _ = try await node64.dns64.status()
        } catch let error as Node64Error {
            switch error {
            case .api(let apiError) where apiError.status == 404:
                // Also returned when the module (e.g. DNS64, DynDNS, Healthchecks) is switched off.
                print("Not found or module disabled:", apiError.error ?? "")
            case .api(let apiError) where apiError.status == 429:
                try await Task.sleep(for: .seconds(apiError.retryAfter ?? 10))
            case .api(let apiError):
                // `error` for developers, `text` (if any) is a localized hint for users,
                // `field`/`fields` name invalid inputs, `code` is machine-readable.
                print(apiError.status, apiError.text ?? apiError.error ?? "", apiError.field ?? "")
            case .missingAPIKey:
                print("Configure a node API key")
            default:
                print(error.localizedDescription)
            }
        }
    }
}

/// Canned-response transport for the executed recipes.
private struct RecipeStub: IPv64Transport {
    var status = 200
    var body: String

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
        else { throw Node64Error.invalidResponse }
        return (Data(body.utf8), response)
    }
}

@Suite("Node64 documentation examples")
struct Node64DocumentationExampleTests {
    private func node(_ stub: RecipeStub) throws -> Node64 {
        let url = try #require(URL(string: "https://node.example.com/api"))
        return Node64(baseURL: url, apiKey: "node64_test", transport: stub)
    }

    @Test("Paging stops when a page is shorter than the limit")
    func eventPaging() async throws {
        let stub = RecipeStub(body: #"[{"id": 3, "to": "down"}, {"id": 2, "to": "up"}]"#)

        let events = try await Node64DocumentationExamples.loadAllEvents(node64: node(stub), checkToken: "abc")

        #expect(events.map(\.id) == [3, 2])
    }

    @Test("DynDNS recipe handles a finished round")
    func dynDNS() async throws {
        let stub = RecipeStub(body: #"{"ipv4": "203.0.113.10"}"#)

        try await Node64DocumentationExamples.runDynDNSCheck(node64: node(stub))
    }

    @Test("Error recipe swallows a disabled module (404)")
    func moduleDisabled() async throws {
        let stub = RecipeStub(status: 404, body: #"{"error": "not found"}"#)

        try await Node64DocumentationExamples.handleErrors(node64: node(stub))
    }
}
