# Node64 – Lücken in der OpenAPI-Spec

Stand: Spec „Node64 – lokale API“ 1.2.0, abgeglichen beim Bau des Swift-Clients `Node64`.
Jede Lücke hier ist im Client mit einer Annahme oder einem untypisierten Rückgabewert gelöst. Wird die Spec ergänzt, lässt sich der Client typisieren.

## 1. 2xx-Antworten ohne Schema

Der Client liefert hier rohes `JSONValue`:

| Endpunkt | Swift-Aufruf |
|---|---|
| `POST /checks`, `PUT /checks/{token}` | `hc.checks.create`, `hc.checks.update` |
| `POST /maintenance`, `PUT /maintenance/{id}` | `hc.maintenance.create`, `hc.maintenance.update` |
| `PUT /channels/{id}` | `hc.channels.update` |
| `GET /channel-types` | `hc.channels.types` |
| `POST /modules/{name}/enable`, `…/disable` | `node.modules.enable`, `node.modules.disable` |
| `GET /dyndns/history` | `dyndns.history` (Prosa nennt nur `truncated`) |
| `POST /dyndns/targets/from-account` | `dyndns.targets.createFromAccount` (Prosa: angelegte Ziele und übersprungene Namen, ohne Feldnamen) |
| `GET /cdn64/status`, `GET /cdn64/stats` | `proxy64.status`, `proxy64.stats` (nur `type: object`; Aufbau von `stats` steht nur in der Beschreibung) |
| `GET /acme-cas/presets` | `certificates.acmeAuthorities.presets` (`[JSONValue]`) |
| `GET /openapi.json` | `node.openAPI` (erwartbar) |

**Vorschlag:** Bei `POST/PUT /checks` und `/maintenance` das angelegte bzw. geänderte Objekt als `Check` bzw. `Maintenance` dokumentieren.

## 2. Antworten nur in Prosa beschrieben

Diese Antworten hat der Client aus dem Beschreibungstext modelliert. Alle Felder sind optional, die Feldnamen sind teils geraten:

- `GET /health`: `{status, version, time}`
- `GET /dyndns/status`, `POST /dyndns/check`: IPv4/IPv6/Präfix, Verbindung, Limit. `targets` („nach Status“) bleibt `JSONValue`.
- `POST /dyndns/targets/{id}/update`: `{result, target}`
- `POST /channels/{id}/test`: `{ok, error}`
- `GET/POST /push/{token}`: `{"status":"ok"}`
- `GET /channels/{id}`: Antwort „OK“ ohne Schema; der Client nimmt `Channel` an.
- `GET /check-types`: Form unbekannt; der Client akzeptiert ein String-Array, ein Objekt-Array oder `{"types": […]}`.
- `GET /modules`: `changed` und der Changelog-Schlüssel (`changelog` angenommen) stehen nur im Text.
- `PUT /logging`: liefert `{level, modules}`, `GET` zusätzlich `known_modules`.
- `PUT /edge/ui`: Antwort dokumentiert nur `name` und `public`.
- Dateien ohne Content-Type: `GET /dns64/records/export`, `GET /cas/{id}/file`.

## 3. Zeitstempel ohne `format: date-time`

Diese Felder sind im Client deshalb `String` statt `Date`:

- `Check.created_at`, `updated_at`
- `State.since`, `last_check_at`, `last_push_at`, `next_check_at`
- `Event.time`, `Measurement.time`, `Incident.started_at`, `ended_at`
- `Stats.from`, `to`, `series[].time`
- `Channel.last_used_at`
- `Link.last_sync_at`, `connected_at`, `linked_at`
- `Maintenance.start_at`, `end_at`, `repeat_until`. Widersprüchlich: `MaintenanceInput` deklariert dieselben Felder als `date-time`.
- Query `from`/`to` von `GET /checks/{token}/measurements`

## 4. PUT-Semantik nicht angegeben

Teilweise ändern oder vollständig ersetzen? Unklar bei:

- `PUT /channels/{id}`, `PUT /honeypot/config`, `PUT /logging`
- `PUT /dns64/groups/{id}/rules`, `PUT /cdn64/access-lists/{id}` (außer: `users` wird ersetzt), `PUT /cdn64/settings`, `PUT /edge/ui`, `PUT /certs/account`
- `PUT /dns64/records|forwards|rewrites|zones/{id}`: Die Pflichtfelder deuten auf vollständiges Ersetzen hin. Unklar ist, ob weggelassene optionale Felder (`ttl`, `comment`, `local_only`, SOA-Werte) zurückgesetzt werden.

## 5. Sonstige Inkonsistenzen

- `POST /link/conflicts/{id}`: Der Pfadparameter ist `string`, die Konflikt-`id` in der Liste ist `integer`.
- `POST /group/join`: `addr` und `code` sind nicht als `required` markiert, aber zwingend nötig.
- `DELETE /cdn64/limits/bans/{ip}`: Der Wert kann ein IPv6-`/64` enthalten. Der Client kodiert `/` als `%2F`, der Server muss das dekodieren. Alternative: Query-Parameter oder Wert ohne Präfixlänge.
- `DNS64Zone.dynamic` / `tsig_name`: als `readOnly` markiert, laut Text „auf der Seite einschaltbar“. Dafür gibt es keinen API-Endpunkt.
- `readOnly` ist nur teilweise gesetzt, obwohl viele Schemas zugleich Antwort und Request-Body sind (`DNS64Record`, `DNS64Forward`, `DNS64Rewrite`, `DNS64Zone`, `DNS64GroupMember`, `DNS64GroupDomain`, `DNS64Schedule`, `DNS64Settings`, `Check`, `StatusPage`, `Channel`). Eigene `…Input`-Schemas oder konsequentes `readOnly` würden Clients eindeutig machen.
- Identifikatoren wie `id` in `DNS64Record`, `ProxyHost`, `Certificate`, `CA` sowie `Measurement.seq` und `ClusterMember.node_id` sind nicht `required`. Der Client behandelt sie trotzdem als nicht-optional.
- Keine `operationId`s: Generatoren müssen Namen raten.
- Ein Fehlerbeschreibungstext steht als Response-Objekt statt als `description` (`POST /cdn64/hosts` → `422`).
- `servers` nennt `http://node.seb.home64.de/api`, eine konkrete, private Node über HTTP. Für eine allgemeine Spec wäre eine Server-Variable passender (`{scheme}://{host}/api`).
