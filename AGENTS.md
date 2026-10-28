# AGENTS.md – integrating the IPv64 package

Guide for AI coding agents (and humans) that add the IPv64.net API v2 to an app with this Swift package.
Read this file first, then look up exact signatures instead of guessing them.

## Where to look

| Need | File |
|---|---|
| Rules, pitfalls, recipes | this file |
| Every method: Swift call path ↔ HTTP endpoint, signature, summary | [`docs/API_REFERENCE.md`](docs/API_REFERENCE.md) |
| Every model: properties, types, open-enum constants | [`docs/MODELS.md`](docs/MODELS.md) |
| Recipes as compiling code | [`Tests/IPv64Tests/DocumentationExamples.swift`](Tests/IPv64Tests/DocumentationExamples.swift) |
| Where the spec is incomplete and how the client handles it | [`docs/IPV64_SPEC_GAPS.md`](docs/IPV64_SPEC_GAPS.md) |
| Source of truth | `Sources/IPv64/API/*.swift` (one file per area), `Sources/IPv64/Models/**` |
| Upstream API | https://ipv64.net/api_v2_docs, spec: https://ipv64.net/api/v2/openapi.json |

To find the Swift method for a known HTTP endpoint, search `docs/API_REFERENCE.md` for it, e.g. `PATCH /records/{record}`.
Each method's doc comment in the sources also ends with its endpoint, so `grep -rn "PATCH /records" Sources` works too.

## Facts

- Module and product name are both `IPv64`. The client class is `IPv64`. Swift 6, iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+. No dependencies.
- Every endpoint method is `async throws` and throws `IPv64Error`. There are no completion-handler or Combine variants.
- `IPv64` is an immutable `final class` that is `Sendable`. Create **one** instance and share it. It is safe to use from any actor or task.
- The endpoints are grouped by area: `ipv64.<area>.<method>`, e.g. `ipv64.records.create(domain:type:prefix:content:)`.
  Areas: `meta`, `account`, `apiKeys`, `domains`, `records`, `integrations`, `healthchecks`, `failover`,
  `statusPages`, `offlinePages`, `cdn` (`.records`, `.mappings`, `.accessList`), `dns64` (`.rules`, `.sources`),
  `cloudRouters` (`.routes`, `.firewall`, `.publicIPs`), `gateways` (`.portForwards`, `.peers`), `peers`,
  `hc2` (`.checks`, `.channels`, `.maintenances`, `.incidents`, `.nodes`), `honeypot`, `threat` (`.watch`).
- Responses are unwrapped for you: methods return the model, not the `{"data": …}` envelope.

## Rules

1. **Never build URLs or HTTP requests yourself** for ipv64.net/api/v2. Every endpoint has a method. Path values are percent-encoded automatically (IPv6 addresses, domain names).
2. **Never put the API key in a URL, log or source file.** Load it from the Keychain or configuration and pass it to `IPv64(apiKey:)`. `IPv64(apiKey: nil)` is valid for public endpoints (`meta`, `threat.ip`, `threat.stats`, `threat.passwordRange`); others then throw `IPv64Error.missingAPIKey` without sending anything.
3. **Do not add an `X-IPv64-Act-As` header or parameter.** To manage another account, use `let other = ipv64.actingAs("id-or-email")`.
4. **Unwrap optional model properties.** The spec marks almost no response fields as required, so only identifiers (`id`, `token`, `nodeID`, …) are non-optional. Write `domain.name ?? ""`, not `domain.name!`.
5. **Open enums need a `default` branch.** Types like `RecordType`, `DomainKind` and `CloudRouterState` are `IPv64OpenEnum` structs, not Swift enums. Use the constants (`.a`, `.ready`) for comparisons, and `switch` with `default:`. Unknown server values decode as `Type(rawValue: "…")` instead of failing.
6. **Use the identifier type of the signature.** Some areas use `Int` IDs, others `String` IDs or tokens:
   - `Int`: `apiKeys`, `integrations`, `statusPages`, `hc2.channels`, `hc2.maintenances`, `cdn.accessList`, `dns64.rules`, `cloudRouters.routes/firewall/publicIPs`, `gateways.portForwards`, `threat.watch`.
   - `String`: `domains` (ID or name), `records` (ID or record token), `healthchecks`, `hc2.checks` (token), `hc2.nodes` (node ID), `failover`, `offlinePages`, `cdn` (token), `cdn.mappings`, `dns64` (token), `dns64.sources`, `cloudRouters`, `gateways`, `peers`.
   - A numeric record ID is passed as a string: `ipv64.records.get(String(record.id))`.
7. **PATCH sends only what you pass.** `nil` means "leave unchanged". Where the API allows it, an empty string `""` clears a value. Update methods take either labeled parameters or a `…Input` struct (`update(_ id, _ input)`); build the input with only the fields you want to change.
8. **202 Accepted means "in progress".** Many CDN, Cloud Router, Gateway, Peer, DNS64 and DNS-Failover changes return the new state immediately and finish in the background. Poll the matching `get` every few seconds until:
   - `state == .ready` (gateways, peers, port forwards, routes, firewall rules, public IPs, DNS64 clients),
   - `pending` is empty (CDN domains),
   - `status` is no longer `.failoverRequested` / `.fallbackRequested` (failover policies).
   While a gateway or peer is being set up, other changes fail with 409 and `retryAfter`.
9. **Respect rate limits.** 300 requests per account burst, refilling 10/s. On 429 (and some 409) wait `problem.retryAfter` seconds before retrying. Do not retry other 4xx errors.
10. **Pagination is cursor-based.** `account.logs`, `healthchecks.events`, `hc2.events` and `hc2.checks.events` return `IPv64Page<Item, Meta>`: read `page.items`, then pass `page.meta?.nextBefore` as `before:` for older entries. The event lists also accept `after:` (cursor `page.meta?.nextAfter`, ascending order) to fetch only new entries; loop while `page.meta?.hasMore == true`.
11. **Dates are `Date`.** Timestamps (ISO 8601 with time zone) decode to `Date`, and `Date` parameters are encoded for you. Fields documented as a calendar date (`format: date`) are `String` (`"2026-10-10"`).
12. **The DynDNS endpoint of this API is `ipv64.domains.updateDynDNS(...)`.** The legacy `update.php` URL for routers is a different API and is not part of this package.

## Errors

```swift
do {
    _ = try await ipv64.domains.create(name: "meinname.ipv64.de")
} catch let error as IPv64Error {
    switch error {
    case .api(let problem):
        // problem.code: machine-readable ("domain_taken", "limit_reached", "invalid_field", …)
        // problem.detail: human-readable message, problem.field: affected input field
        // problem.status: HTTP status, problem.retryAfter: seconds (429 and some 409)
        print(problem.code, problem.detail)
    case .missingAPIKey:
        break // configure an API key
    case .httpStatus(let code, _):
        print("HTTP \(code) without problem document")
    case .decoding(let underlying, let body):
        print(underlying, String(decoding: body, as: UTF8.self))
    default:
        print(error.localizedDescription)
    }
}
```

`error.statusCode` and `error.code` are shortcuts. The full list of error codes is in the upstream docs (section *Fehler*).

## Testing app code

Inject a stub transport instead of hitting the network:

```swift
struct StubTransport: IPv64Transport {
    let json: String
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (Data(json.utf8), response)
    }
}

let ipv64 = IPv64(apiKey: "test", transport: StubTransport(json: #"{"data":[]}"#))
```

Responses must use the API's envelope: `{"data": …}`; errors use `application/problem+json`
(`{"type": "…", "title": "…", "status": 404, "detail": "…", "code": "…"}`).

## Recipes

Recipes that call `ipv64.…` assume a shared `IPv64` client (see Setup). Two recipes throw this small helper error:

```swift
enum RecipeError: Error {
    case timedOut
    case cryptoKitUnavailable
}
```

### Setup: one shared client

Create the client once and share it; `IPv64` is an immutable `Sendable` class, so no actor is needed.

```swift
func makeClient() -> IPv64 {
    // Read the key from the environment, or from the Keychain in a real app.
    let apiKey = ProcessInfo.processInfo.environment["IPV64_API_KEY"]
    // `apiKey: nil` is fine for public endpoints such as `threat.ip(_:)`.
    return IPv64(apiKey: apiKey)
    // SwiftUI: keep it in a small `@Observable` model or an `EnvironmentKey` and inject the same instance.
    // Switch the header style with `IPv64(configuration: .init(apiKey: key, authentication: .apiKeyHeader))`.
}
```

### DynDNS: update a domain's IP

Set the A and AAAA record of a DynDNS domain (or one prefix) and inspect what happened per address. (`ipv64` is your shared client.)

```swift
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
```

### DNS records: list, create, update, delete

Manage records; domains take an ID or full name, single records take their numeric ID or their token (both as `String`). (`ipv64` is your shared client.)

```swift
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
```

### Create a domain and handle domain_taken / limit_reached

Create a DynDNS domain and react to the two expected business errors. (`ipv64` is your shared client.)

```swift
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
```

### Classic healthcheck: create, pause, resume, read events

Create a push healthcheck, pause and resume it, then read all events page by page with cursors. (`ipv64` is your shared client.)

```swift
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
```

### Healthchecks 2.0: HTTP check, list, stats

Create an HTTP check measured from both online locations, list checks and read availability. (`ipv64` is your shared client.)

```swift
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
```

### Async 202 resources: poll until ready

Generic poller: calls `fetch` until `isDone` holds, honors cancellation and gives up after `maxAttempts`.

```swift
func poll<Value: Sendable>(
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

func waitForAsyncResources(ipv64: IPv64) async throws {
    // Creating a router also creates its first gateway, but the 202 answer may not list it yet.
    let router = try await ipv64.cloudRouters.create(name: "Home Lab")
    let routerWithGateway = try await poll {
        try await ipv64.cloudRouters.get(router.id)
    } until: { router in
        !(router.gateways ?? []).isEmpty
    }
    guard let gateway = routerWithGateway.gateways?.first else { throw RecipeError.timedOut }

    // Gateway: ready once `state == .ready` (it starts as `.creating`).
    // Use `cloudRouters.createGateway(router:name:)` only for additional gateways.
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
```

### Rate limiting: retry on 429 and 409 with retryAfter

Run `operation`, waiting `problem.retryAfter` seconds and retrying on 429 or a 409 that carries a retry hint.

```swift
func withRetry<Value: Sendable>(
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

func useRetry(ipv64: IPv64) async throws {
    let peer = try await withRetry {
        try await ipv64.gateways.peers.create(gateway: "gateway-token", name: "Laptop")
    }
    print("created peer", peer.id)
}
```

### Acting for another account

Use `actingAs(_:)` to manage an account that shared its administration with you (header `X-IPv64-Act-As`). (`ipv64` is your shared client.)

```swift
// Account ID or e-mail address of the other account. The original client is unchanged.
let customer = ipv64.actingAs("customer@example.com")
let domains = try await customer.domains.list()
print("customer has \(domains.count) domains")
```

### Threat: look up an IP and check a password

Look up an IP on the v64 Blocklist; this works without an API key.

```swift
func lookUpIP() async throws {
    let anonymous = IPv64(apiKey: nil)
    let info = try await anonymous.threat.ip("198.51.100.23")
    if info.listed == true {
        print("listed with score \(info.score ?? 0), lists:", info.lists?.count ?? 0)
    }
}

func isPasswordSeenInAttacks(_ password: String, ipv64: IPv64) async throws -> Bool {
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
```

### Peers: download the WireGuard config

Fetch the WireGuard `.conf` of a peer as text (it contains the private key, treat it as a secret).

```swift
func downloadWireGuardConfig(ipv64: IPv64) async throws -> String {
    try await ipv64.peers.config("peer-token")
}
```

### Error handling pattern

Switch over `IPv64Error` and branch on the machine-readable `code`. (`ipv64` is your shared client.)

```swift
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
```

### Testing your app code: a stub transport

Returns one canned response for every request; the API wraps payloads in a `{"data": ...}` envelope.

```swift
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

func listDomainsWithStub() async throws -> [Domain] {
    let stub = StubTransport(json: #"{"data": [{"id": 1, "name": "home.ipv64.de", "kind": "dyndns"}]}"#)
    let ipv64 = IPv64(apiKey: "test-key", transport: stub)
    return try await ipv64.domains.list()
}
```

All recipes are compiled in `Tests/IPv64Tests/DocumentationExamples.swift`; `RecipeError`, `poll`, `withRetry` and `StubTransport` are defined there.

# Node64 – the local node API

The same package also contains `Node64`, a client for the local JSON API of a Node64 node running in your own network.
Everything above about `IPv64` does **not** automatically apply here; read this section.

| Need | File |
|---|---|
| Every Node64 method: call path ↔ HTTP endpoint, signature, summary | [`docs/NODE64_API_REFERENCE.md`](docs/NODE64_API_REFERENCE.md) |
| Every Node64 model | [`docs/NODE64_MODELS.md`](docs/NODE64_MODELS.md) |
| Recipes as compiling code | [`Tests/IPv64Tests/Node64/Node64DocumentationExamples.swift`](Tests/IPv64Tests/Node64/Node64DocumentationExamples.swift) |
| Where the spec is incomplete | [`docs/NODE64_SPEC_GAPS.md`](docs/NODE64_SPEC_GAPS.md) |
| Source | `Sources/IPv64/Node64/` (`API/` one file per area, `Models/`) |

## Facts

- `import IPv64`, then `Node64(baseURL:apiKey:)`. The base URL is required and points to the node's API root (e.g. `https://node.example.com/api`). Use one client per node.
- API keys look like `node64_…` and are sent as `Authorization: Bearer`. `Configuration.agentActor` sets `X-Agent-Actor`, the name shown in the node's audit log.
- All models are **nested in `Node64`** (`Node64.Check`, `Node64.APIKey`, `Node64.StatusPage`) so they never collide with the ipv64.net models of the same name. Always qualify them.
- Errors are `Node64Error`, not `IPv64Error`. `.api(Node64APIError)` carries `status`, `error`, `field`, `fields`, `code`, `key`, `text` and `retryAfter`.
- Responses have **no** `{"data": …}` envelope. Lists are plain arrays (no `IPv64Page`).
- Areas: `node` (`.modules`, `.apiKeys`), `hc` (`.checks`, `.maintenance`, `.onlineChecks`, `.channels`, `.statusPages` (`.notices`), `.docker` (`.systems`), `.proxmox` (`.systems`)), `dyndns` (`.targets`), `dns64` (`.lists`, `.upstreams`, `.cache`, `.allowlist`, `.records`, `.groups` (`.members`, `.domains`, `.schedules`), `.devices`, `.forwards`, `.rewrites`, `.zones`), `proxy64` (`.hosts`, `.streams`, `.accessLists`, `.blocklists`, `.honeypot`, `.limits`, `.online`), `ports` (`.edge`), `certificates` (`.account`, `.dnsAccounts`, `.authorities`, `.acmeAuthorities`), `link`, `cluster`, `honeypot`.

## Rules

1. **Read the doc comment of every update method before calling it.** Node64 updates with `PUT`, and the semantics differ per endpoint:
   - `hc.checks.update` always takes `name`, `type` and `target`, and **clears `description` when it is `nil`**. Build the input from the current check (see the recipe).
   - `hc.maintenance.update` and the DNS64 `records`/`forwards`/`rewrites`/`zones` updates replace the whole object.
   - `dns64.updateSettings` changes only the given fields, but `upstreams` and `lists` replace the whole list.
   - `hc.statusPages.update`: `groups` replaces all groups (their IDs change); `password: "-"` removes the password.
   - `ports.edge.update`, `proxy64.honeypot.update`, `proxy64.limits.update`: missing fields stay unchanged.
2. **Some methods return `JSONValue`** because the spec documents no response body (e.g. `hc.checks.create/update`, `hc.maintenance.create/update`, `proxy64.status()`). Read values with `result["token"]?.stringValue`. The list is in `docs/NODE64_SPEC_GAPS.md`.
3. **404 can mean "module switched off"**, not only "not found" (Healthchecks, DynDNS, DNS64, …). Check `node64.node.modules.list()` before assuming a missing resource.
4. **Rate limit per IP:** 429 with `Retry-After` (about 10 s); after 5 invalid API keys only one attempt per 30 s. Wait `retryAfter` seconds.
5. **Push heartbeats need no API key:** `Node64(baseURL:apiKey: nil).hc.push(token, status:message:)`. The check token is the secret.
6. **Downloads are `Data`** (`node.downloadDatabase()`, certificate bundles/P12, `dns64.caCertificate()`, `dns64.mobileConfig(...)`). Backups and key material are secrets: store them encrypted, never log them.
7. **Destructive calls** (`node.restoreBackup`, `node.importConfiguration`, `node.reset`, `link.unlink`, `cluster.leave`) need explicit user confirmation in your app.
8. **Some timestamps are `String`**, because the spec does not mark them as `date-time` (e.g. `Check.createdAt`, `CheckState.since`, `CheckEvent.time`). Parse them with `ISO8601DateFormatter` when needed.
9. **Paging:** lists with `before` (events, measurements, audit, deliveries, PROXY64 log) return the newest entries; pass the last item's `id` (or `seq`) as `before` for older ones. `dns64.log` uses `limit`/`offset`.
10. Open enums, optional properties and identifier types work as for `IPv64` (rules 4–6 above): unwrap optionals, `switch` with `default`, use the parameter type of the signature.

## Node64 recipes

All compile in `Tests/IPv64Tests/Node64/Node64DocumentationExamples.swift`; `node64` is your shared client.

### Setup: one client per node

```swift
func makeNodeClient() throws -> Node64 {
    guard let baseURL = URL(string: "https://node.example.com/api") else {
        throw Node64Error.invalidRequest("Invalid node URL")
    }
    // API key from the node's settings (Einstellungen > API-Keys), e.g. from the Keychain.
    let apiKey = ProcessInfo.processInfo.environment["NODE64_API_KEY"]
    // `agentActor` is the name shown in the node's audit log for changes made by this app.
    return Node64(configuration: .init(baseURL: baseURL, apiKey: apiKey, agentActor: "My App"))
}
```

### Healthchecks: find down checks and pause one

```swift
let down = try await node64.hc.checks.list(state: .down)
for check in down {
    print("\(check.name ?? check.token) is down")
}
if let first = down.first {
    let paused = try await node64.hc.checks.pause(first.token)
    print("paused", paused.token)
}
```

### Healthchecks: create and safely update a check

`PUT /checks/{token}` always takes name, type and target and clears a missing description, so build the update from the current check.

```swift
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
```

### Push heartbeat from a script

```swift
// Push endpoints need no API key; the check token authorizes the heartbeat.
let anonymous = Node64(baseURL: baseURL, apiKey: nil)
_ = try await anonymous.hc.push(
    checkToken,
    status: backupFailed ? .down : .up,
    message: backupFailed ? "Backup failed" : nil
)
```

### Events: page with the `before` cursor

```swift
var events: [Node64.CheckEvent] = []
var before: Int?
while true {
    try Task.checkCancellation()
    let page = try await node64.hc.checks.events(checkToken, limit: 100, before: before)
    events += page
    guard page.count == 100, let last = page.last else { break }
    before = last.id
}
```

### DynDNS: trigger an update round

```swift
switch try await node64.dyndns.check() {
case .completed(let status):
    print("IPv4:", status.ipv4 ?? "-", "IPv6:", status.ipv6 ?? "-")
case .running:
    // Still running after 45 s: read the result later.
    let status = try await node64.dyndns.status()
    print("current IPv4:", status.ipv4 ?? "-")
}
```

### Backup: download the database

```swift
// The SQLite database contains all secrets of the node; store it encrypted.
let database = try await node64.node.downloadDatabase()
try database.write(to: url, options: [.atomic, .completeFileProtection])
```

### Error handling

```swift
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
```

## Maintaining these docs

`docs/API_REFERENCE.md`, `docs/MODELS.md`, `docs/NODE64_API_REFERENCE.md` and `docs/NODE64_MODELS.md` are generated.
After changing the public API, run `python3 Scripts/generate_docs.py` and commit the result.
