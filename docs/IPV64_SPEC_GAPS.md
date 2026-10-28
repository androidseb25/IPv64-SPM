# IPv64 – Lücken in der OpenAPI-Spec

Stand: Spec „IPv64.net API“ 2.0.0 (OpenAPI 3.1.0, 192 Operationen), abgerufen am 28.10.2026 von `https://ipv64.net/api/v2/openapi.json` und mit dem Swift-Client `IPv64` abgeglichen.
Jede Lücke hier löst der Client mit einer Annahme, einem nachsichtigen Decoder oder einem untypisierten Rückgabewert. Wird die Spec ergänzt, lässt sich der Client typisieren.

## 1. 2xx-Antworten ohne oder mit widersprüchlichem Schema

| Endpunkt | Problem | Swift-Aufruf |
|---|---|---|
| `GET /node64/nodes` | 200 ohne `content` | `hc2.nodes.containers()` liefert `JSONValue` |
| `POST /hc2/channels/{id}/verify/send`, `POST /hc2/channels/{id}/verify` | 200 ohne `content`. Nur die Beschreibung von `/verify/send` nennt `verified: true` (Kanal schon bestätigt) | `hc2.channels.sendVerificationCode`, `hc2.channels.verify` liefern `JSONValue`: den Inhalt von `data`, falls vorhanden, sonst den ganzen Body |
| `GET /openapi.json` | Das Schema hat eine `{"data": …}`-Hülle, deren Feld `data` aber „OpenAPI-Dokument (ohne data-Hülle)“ heißt. Ausgeliefert wird das Dokument ohne Hülle | `meta.openAPIDocument()` liest ohne Hülle |
| `Hc2Check.nodes` | Das Schema sagt `string[]` (Node-IDs), die Beschreibung desselben Felds „Ausgabe: Liste {node_id, name}“. `Hc2CheckInput.nodes` ist identisch definiert und beschrieben | `HC2Check.NodeReference` decodiert beide Formen |

**Vorschlag:**
- Für die drei Endpunkte ohne `content` Schemas ergänzen: z. B. `Node64Container` in `{data: […]}` und `{data: {verified: boolean}}`.
- Bei `GET /openapi.json` das 200-Schema auf `type: object` ändern.
- `Hc2Check.nodes` als `{node_id, name}[]` definieren; `Hc2CheckInput.nodes` bleibt `string[]`.

## 2. Nur in Prosa beschrieben

- **`POST /node64/hello`:**
  - Der Pflicht-Header `X-Node64-Node` steht nur in der Beschreibung und ist nicht als `in: header`-Parameter deklariert.
  - Die 403-Antwort (`node_removed`) hat keinen Inhalt; ein `$ref` auf `E403` würde reichen.
- **`Retry-After`:**
  - Der Header ist an keiner Antwort unter `headers` deklariert und wird nur bei `POST /honeypot/reports` im Text erwähnt.
  - Das Beispiel in `E429` hat kein `retry_after` und nennt die Wartezeit nur im `detail`-Text.
  - Unklar ist, ob Body-Feld oder Header gilt. Der Client liest `retry_after` und nimmt sonst den Header.
- **`ETag` bei `GET /threat/feed`:** Der Header steht nur im Text („Kopfzeile ETag“), nicht unter `headers`. Die 304-Antwort ist korrekt deklariert.
- **Abfragen nach 202:**
  - 46 Operationen antworten mit 202. 39 davon haben denselben allgemeinen Text („Die Änderung wird … vom Hintergrunddienst umgesetzt“), die übrigen sieben eigene Kurztexte: `PATCH /peers/{token}`, `PATCH /dns64/clients/{token}`, `POST /hc2/checks/{token}/run`, `POST /hc2/checks/{token}/move`, `POST /hc2/nodes/link`, `POST /hc2/nodes/{node_id}/commands`, `POST /honeypot/reports`.
  - Woran man das Ende erkennt, steht nur vereinzelt: `POST /dns64/clients` (`state` ready), Tag CDN (`pending`), `POST /hc2/checks/{token}/move` (`GET /hc2/testruns/{id}` alle 2 s, höchstens 60 s).
  - Für Cloud Router, Gateways, Peers, Port-Forwards und DNS-Failover fehlt der Hinweis (`state == ready` bzw. Failover-`status`), ebenso ein Abfrage-Intervall.
- **`POST /cloud-routers`:**
  - Laut Text legt die Operation Router **und** erstes Gateway an.
  - `CloudRouter` hat kein `state`, und ob die 202-Antwort das Gateway schon enthält, sagt die Spec nicht. Das Rezept in `AGENTS.md` fragt den Router ab, bis `gateways` gefüllt ist.
- **Rate-Limits:** Die allgemeinen Limits (300 Anfragen Burst, 10/s) stehen nirgends in der Spec, nur Sonderlimits bei Threat und Honeypot64.
- **Fehlercodes:** `Problem.code` hat weder `enum` noch Liste. Die Codes stehen nur in der Doku (Abschnitt *Fehler*).
- **Verify-Endpunkte:**
  - `422 invalid_code` steht nur in der Beschreibung.
  - 404 und 429 sind reine Beschreibungen statt `$ref: E404/E429`.
  - Ein 401-Eintrag fehlt; ebenso bei `POST /hc2/channels/{id}/send`.
- **Prosa-Parameter:**
  - `source` bei `GET /hc2/checks/{token}/measurements` mit den Werten `loc:nbg`, `loc:fsn` und `node:<id>`.
  - `since` bei `GET /threat/watch/alerts`: Cursor oder RFC-3339-Zeit.
- **Mindestintervall:** `interval_seconds` bei `POST /healthchecks` und `PATCH /healthchecks/{token}` nennt „Free-Paket mindestens 120 Sekunden“ nur im Text; das Schema sagt `minimum: 1`.

**Vorschlag:**
- `X-Node64-Node`, `Retry-After` und `ETag` als Parameter bzw. Header deklarieren.
- Das Abfrage-Verfahren nach 202 einmal zentral beschreiben (`info.description` oder `x-`-Erweiterung).
- `Problem.code` als `enum` oder mit Verweis auf die Fehlerliste angeben.

## 3. Zeitstempel und `nullable`

- `Peer.last_handshake` ist `string|null` ohne `format`, als einziges Zeitfeld. Der Client hält es als `String?`.
- `first_seen`/`last_seen` sind bei `ThreatIp` und `ThreatWatchAlert` `format: date`, bei `HoneypotSensor` und `Hc2Node` dagegen `format: date-time`.
- An 29 Stellen steht `nullable: true` im Stil von OpenAPI 3.0 (z. B. `Hc2Command.created_at`, `done_at`). Das Dokument ist 3.1, dort gilt `type: ["string", "null"]`; Werkzeuge für 3.1 ignorieren `nullable`.
- `Hc2MaintenanceInput.start_at` und `end_at` sind zugleich `required` und nullable.

## 4. Typen und Pflichtfelder

- **Pfad-IDs als `string`, Modell-IDs als `integer`:** `{id}` ist überall außerhalb von HC2 `type: string` (meist mit dem allgemeinen Text „ID der Ressource“), obwohl diese Modelle `id: integer` haben:
  - `/api-keys/{id}`, `/integrations/{id}`, `/status-pages/{id}`, `/threat/watch/{id}`
  - `/cdn/{token}/access-list/{id}`, `/peers/{token}/allowed-ips/{id}`
  - die Cloud-Router-`routes`, `firewall` und `public-ips`
  - die Gateway-`port-forwards`
  - die DNS64-`rules`

  Bei `/failover/policies/{id}`, `/offline-pages/{id}` (16-stellige IDs) und den DNS64-`sources` (ID oder Record-Token) ist `string` richtig. `/hc2/channels`, `/hc2/maintenance` und `/hc2/testruns` sind korrekt `integer`. Der Client verwendet die Typen der Modelle (siehe `AGENTS.md`, Regel 6).
- **Boolesche Query-Parameter:** `include_secrets` ist `string` mit `enum: ["true", "false"]`, `open` bei `/hc2/incidents` dagegen `boolean`. Der Client sendet `Bool` immer als `"true"`/`"false"`.
- **Pflichtfelder:**
  - 55 von 61 Objekt-Schemas haben gar keine `required`-Liste (u. a. `Me`, `Record`, `Domain`, `Healthcheck`, `Hc2Check`, `Gateway`).
  - Auch Identifikatoren sind nie `required`: keine der 40 Eigenschaften `id` oder `token` auf oberster Ebene der Komponenten-Schemas, z. B. `Record.id`, `Record.token`, `Healthcheck.token`, `Hc2Check.token`, `Hc2Event.id`, `Gateway.id`.
  - Von den 20 Inline-Schemas für `data` mit `properties` hat nur eines eine `required`-Liste (`GET /honeypot/list-token`); es fehlt z. B. bei `GET /health` und `GET /ip`.
  - Folge: Fast alle Felder sind im Client optional; nicht-optional sind die Identifikatoren, die er trotzdem voraussetzt, und die wenigen als `required` markierten Felder.
- **Gleicher Name, anderer Typ:**
  - `family` ist in `FirewallRule` ein String, in `ThreatIp` eine Zahl.
  - `state` ist meist ein String, in `Hc2Check` ein Objekt.
  - `accepted` ist einmal Zahl, einmal boolesch.
  - `created_at` ist an 17 von 19 Stellen nullable (14× `type: [string, null]`, 3× `nullable: true`), bei `ThreatWatchNetwork` und `ThreatWatchAlert` nicht. Von allen 82 `date-time`-Feldern sind 65 nullable, in beiden Schreibweisen gemischt.
- **Werte-Listen gleichnamiger Enums:**
  - `state` hat sieben verschiedene Wertemengen: `creating` gibt es nur bei `Gateway`, bei `PublicIp` und `Dns64Client` fehlt `deleting`.
  - `action` hat drei: accept/drop, allow/block und add/remove/update.
  - `range` unterscheidet sich zwischen Healthchecks (1 h bis 30 d) und HC2 (24 h bis 1 y).
- **Freie Objekte ohne Schema:** `Integration.options`, `Hc2Channel.config`, `HealthcheckEvent.payload`, `Hc2Measurement.details`, `Hc2Command.args`; `Hc2Command.output` hat gar keinen Typ. Der Client liefert dort `JSONValue`.
- **Paging-Meta:** Die Meta-Daten von `/me/logs` haben kein `has_more` (Ende bei `next_before: null`), die Event-Listen schon (`has_more`, `next_before`, `next_after`).

**Vorschlag:**
- Pfad-`{id}` dort als `integer` deklarieren, wo das Modell `id: integer` hat.
- `required` mindestens für Identifikatoren und immer vorhandene Felder setzen.
- Ein gemeinsames `PageMeta` verwenden.
- Für `Integration.options` und `Hc2Channel.config` je Typ ein `oneOf` angeben.

## 5. Sonstige Inkonsistenzen

- `DELETE /hc2/nodes/{node_id}` hat einen Request-Body mit `required: true`, dessen einziges Feld (`keep_checks`) optional ist. Bodys bei `DELETE` lassen manche Proxys und HTTP-Clients nicht durch; ein Query-Parameter wäre robuster. Der Client sendet immer einen JSON-Body.
- Den beiden Verify-Endpunkten fehlt die `operationId`. Alle anderen Operationen haben eine.
- Fehlerantworten ohne Schema: `POST /node64/hello` 403 sowie 404 und 429 der beiden Verify-Endpunkte.
- `info.description` verweist auf `https://ipv64.net/api/v2/docs`. Die Adresse leitet auf `https://ipv64.net/api_v2_docs` weiter; der direkte Link wäre stabiler.
