# IPv64

Swift-Package für die [IPv64.net API v2](https://ipv64.net/api_v2_docs): DynDNS, DNS, Healthchecks (klassisch und 2.0), DNS-Failover, Statusseiten, Offline-Pages, CDN, Cloud Router, Gateways, Peers, DNS64, Honeypot64 und Threat Intelligence.

Das Package deckt alle 189 Endpunkte der OpenAPI-Spezifikation (`https://ipv64.net/api/v2/openapi.json`) ab.

Zusätzlich enthält es `Node64`, einen Client für die lokale API einer Node64-Node im eigenen Netz, mit allen 290 Endpunkten (siehe [Node64](#node64)).

- Swift 6 Language Mode mit strikter Concurrency-Prüfung
- `async`/`await`, der Client ist `Sendable` und kann zwischen Tasks und Actors geteilt werden
- Keine Abhängigkeiten außer Foundation
- iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+

## Für KI-Agenten

> **AI coding agents:** read [`AGENTS.md`](AGENTS.md) before integrating this package. It lists the rules and pitfalls, plus recipes for common tasks (the recipes compile in the test target).
> Exact signatures for all 189 endpoints are in [`docs/API_REFERENCE.md`](docs/API_REFERENCE.md), searchable by HTTP endpoint. Every model with its properties and enum constants is in [`docs/MODELS.md`](docs/MODELS.md).
> For the local node API (`Node64`) use [`docs/NODE64_API_REFERENCE.md`](docs/NODE64_API_REFERENCE.md) and [`docs/NODE64_MODELS.md`](docs/NODE64_MODELS.md), and read the Node64 section of `AGENTS.md`.
> Do not guess method names or build URLs yourself.

## Installation

```swift
// Package.swift
dependencies: [
    .package(path: "../IPv64-SPM"), // oder die URL deines Git-Repositorys
],
targets: [
    .target(name: "MyApp", dependencies: ["IPv64"]),
]
```

## Schnellstart

```swift
import IPv64

let ipv64 = IPv64(apiKey: "DEIN_API_KEY")

let me = try await ipv64.account.me()
let domains = try await ipv64.domains.list()
let records = try await ipv64.records.list(domain: "beispiel.ipv64.de")
```

Den API-Key legst du auf ipv64.net unter *Account > API* an.

## Aufbau

Der Client `IPv64` gruppiert die Endpunkte nach den Bereichen der API:

| Eigenschaft | Bereich |
|---|---|
| `meta` | API-Info, Health, eigene IP, OpenAPI-Dokument (ohne API-Key) |
| `account` | `/me`, Logs, Account-Freigaben |
| `apiKeys` | API-Keys anlegen, auflisten und löschen |
| `domains` | Domains, Token rotieren, DynDNS-Update |
| `records` | DNS-Records |
| `integrations` | Benachrichtigungen |
| `healthchecks` | Healthchecks (klassisch) |
| `failover` | DNS-Failover-Policies, Monitore, Regeln |
| `statusPages` | Statusseiten |
| `offlinePages` | Offline-Pages inkl. Icon-Upload |
| `cdn` | CDN-Domains, Records, Port-Mappings, Access-Listen |
| `cloudRouters` | Cloud Router, Routen, Firewall, öffentliche IPs |
| `gateways` | Gateways, Port-Forwards, OSPF |
| `peers` | WireGuard-Peers inkl. Config-Download |
| `dns64` | DNS64-Clients, Regeln, Quellen |
| `hc2` | Healthchecks 2.0: Checks, Kanäle, Wartungen, Incidents, Nodes |
| `honeypot` | Honeypot64-Reports, Sensoren, Statistik |
| `threat` | IP-Reputation, Statistik, Passwort-Range, Blocklist-Feed, Frühwarnung |

Jede Methode nennt in ihrer Dokumentation den zugehörigen Endpunkt, zum Beispiel `` `GET /domains` ``.

## Konfiguration

```swift
let ipv64 = IPv64(configuration: .init(
    apiKey: "DEIN_API_KEY",
    authentication: .apiKeyHeader, // Standard: .bearer (Authorization: Bearer …)
    timeoutInterval: 15
))
```

Öffentliche Endpunkte wie `meta` und Teile von `threat` funktionieren auch ohne API-Key: `IPv64(apiKey: nil)`.

### Für einen anderen Account handeln

Hat dir ein anderer Account die Verwaltung per Account-Freigabe erlaubt:

```swift
let customer = ipv64.actingAs("kunde@example.com") // sendet X-IPv64-Act-As
let customerDomains = try await customer.domains.list()
```

## Fehlerbehandlung

Fehler kommen als `IPv64Error`. API-Fehler (RFC 9457) enthalten das vollständige `IPv64Problem`:

```swift
do {
    try await ipv64.domains.delete("beispiel.ipv64.de")
} catch let error as IPv64Error {
    switch error {
    case .api(let problem) where problem.code == "failover_active":
        print("Erst zurückschalten: \(problem.detail)")
    case .api(let problem) where problem.status == 429:
        try await Task.sleep(for: .seconds(problem.retryAfter ?? 1))
    default:
        print(error.localizedDescription)
    }
}
```

`retryAfter` wird aus dem Body oder dem `Retry-After`-Header gefüllt.

## Seitenweise abrufen

Logs und Events verwenden einen Cursor statt Seitenzahlen. Diese Methoden liefern `IPv64Page<Item, Meta>`:

```swift
var page = try await ipv64.account.logs(limit: 50)
while let before = page.meta?.nextBefore {
    page = try await ipv64.account.logs(limit: 50, before: before)
}
```

## Asynchrone Änderungen

Viele Änderungen bei CDN, Cloud Router, DNS64 und DNS-Failover antworten mit `202 Accepted` und dem neuen Zustand. Die Änderung ist fertig, wenn:

- bei Gateways, Peers, Port-Forwards, Routen, Firewall-Regeln, öffentlichen IPs und DNS64-Clients `state == .ready` ist,
- bei CDN-Domains `pending` leer ist,
- bei Failover-Policies `status` nicht mehr `failover_requested` oder `fallback_requested` ist.

Frage den Eintrag dazu alle paar Sekunden mit `get` ab.

## Aufzählungen

String-Aufzählungen wie `RecordType` oder `DomainKind` sind „offene“ Enums: Sie haben Konstanten für die dokumentierten Werte (`.a`, `.aaaa`, …) und bleiben decodierbar, wenn der Server neue Werte einführt. Verwende in `switch`-Anweisungen deshalb einen `default`-Zweig.

## PATCH-Semantik

Update-Methoden schicken nur die übergebenen Felder; `nil` bedeutet „nicht ändern“. Wo die API das vorsieht, löscht ein leerer String `""` einen Wert.

## Tests und eigene Transporte

Die Netzwerkschicht ist austauschbar. Implementiere `IPv64Transport`, um Antworten in Tests zu stubben oder einen eigenen HTTP-Stack zu verwenden:

```swift
struct MyTransport: IPv64Transport {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) { … }
}

let ipv64 = IPv64(apiKey: "…", transport: MyTransport())
```

Die Tests des Packages laufen mit Swift Testing:

```sh
swift test
```

## Node64

`Node64` ist ein eigener Client für die lokale API einer Node64-Node. Er nutzt denselben Kern (Transport, Datumsformate, offene Enums), hat aber eigene Konventionen:

```swift
import IPv64

let node64 = Node64(configuration: .init(
    baseURL: URL(string: "https://node.example.com/api")!,
    apiKey: "node64_…",          // Einstellungen > API-Keys
    agentActor: "Meine App"      // Name im Audit-Log der Node
))

let down = try await node64.hc.checks.list(state: .down)
let dns = try await node64.dns64.status()
let backup = try await node64.node.downloadDatabase()   // Data, enthält Geheimnisse
```

| Bereich | Inhalt |
|---|---|
| `node` | Status, Module, Einstellungen, API-Keys, Logs, Backup/Restore/Export/Import |
| `hc` | Checks, Events, Wartung, Push, Online-Checks, Kanäle, Statusseiten, Docker, Proxmox |
| `dyndns` | DynDNS-Updater und Ziele |
| `dns64` | Resolver-Statistik, Listen, Upstreams, Cache, Records, Gruppen, Forwards, Rewrites, Zonen |
| `proxy64` | Reverse Proxy: Hosts, Streams, Zugriffslisten, Schutz, ipv64-Online-Anbindung |
| `ports`, `certificates` | Ports, Eingang (Edge), TLS-Zertifikate, CAs, ACME |
| `link`, `cluster`, `honeypot` | Verknüpfung mit ipv64.net, lokaler Node-Verbund, Honeypot64 |

Unterschiede zu `IPv64`:

- Die Basis-URL ist Pflicht, weil jede Node ihre eigene Adresse hat.
- Modelle sind in `Node64` verschachtelt (`Node64.Check`, `Node64.APIKey`) und kollidieren so nicht mit den ipv64.net-Modellen.
- Fehler kommen als `Node64Error`. `.api(Node64APIError)` enthält `status`, `error`, `field`, `fields`, `code`, `text` und `retryAfter`.
- Antworten haben keine `data`-Hülle, Listen sind einfache Arrays.
- Änderungen laufen per `PUT`, je nach Endpunkt teilweise oder als vollständiger Ersatz. **Die Dokumentation jeder `update`-Methode beachten.** Beispiel: `hc.checks.update` verlangt immer `name`, `type` und `target` und leert eine fehlende `description`.
- Einige Methoden liefern `JSONValue`, weil die Spec dort keine Antwort beschreibt. Die Liste steht in [`docs/NODE64_SPEC_GAPS.md`](docs/NODE64_SPEC_GAPS.md).

## Lizenz

Noch festzulegen.
