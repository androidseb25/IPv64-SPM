# Auftrag: IPv64- und Node64-API-Client für Android (Kotlin), Port des Swift-Packages `IPv64`

> Vor dem Einfügen ersetzen:
> - `/Programmierung/Android/IPv64-Package`: Ordner, in dem das neue Kotlin-Projekt entstehen soll (z. B. `~/Programmierung/Android/IPv64-Kotlin`).
> - `de.sr.ipv64api`: eigene Maven-Group-ID, z. B. `de.deinname`. **Nicht** `net.ipv64` verwenden: Die Domain gehört dir nicht.

---

Baue eine Kotlin-Bibliothek, mit der Android-Apps zwei APIs vollständig nutzen können:

1. die **IPv64.net API v2** (Cloud, 192 Endpunkte, Client-Klasse `IPv64`) und
2. die **lokale API einer Node64-Node** im eigenen Netz (290 Endpunkte, Client-Klasse `Node64`, siehe Abschnitt 5).

Es gibt bereits ein fertiges, getestetes Swift-Package (Swift 6) mit genau diesem Umfang. **Es ist deine Vorlage und Referenz.** Übernimm seine Architektur, Benennung und alle fachlichen Entscheidungen 1:1 in idiomatisches Kotlin. Die Zielgruppen beider Bibliotheken sind dieselben Entwickler und dieselben KI-Agenten, deshalb müssen Namespaces und Methodennamen auf beiden Plattformen gleich heißen.

Baue zuerst `IPv64` vollständig (Abschnitte 2 bis 4, Schritte 1 bis 5 in Abschnitt 6) und erst danach `Node64`. Beide Clients teilen sich den Kern.

## 1. Quellen (zuerst lesen)

Swift-Referenz: `/Users/sebastianrank/Programmierung/XCode/IPv64-SPM`

| Datei | Inhalt |
|---|---|
| `AGENTS.md` | 12 Regeln, Stolperfallen, 13 Rezepte. **Komplett lesen.** |
| `docs/API_REFERENCE.md` | Alle 192 Endpunkte: Swift-Aufrufpfad ↔ HTTP-Endpunkt, Signatur, Beschreibung |
| `docs/MODELS.md` | Alle Modelle mit Feldern, Typen, Enum-Konstanten |
| `docs/IPV64_SPEC_GAPS.md` | Lücken der IPv64-Spec und wie der Swift-Client sie löst |
| `Sources/IPv64/IPv64.swift`, `Sources/IPv64/Core/*` | Client, Konfiguration, Transport, Request-Bau, Fehler, Datumscodierung, offene Enums, Multipart |
| `Sources/IPv64/API/*.swift` | Endpunkte je Bereich (Doc-Kommentar jeder Methode endet mit `` `METHODE /pfad` ``) |
| `Sources/IPv64/Models/**` | Modelle inkl. `CodingKeys` (= exakte JSON-Schlüssel) |
| `Tests/IPv64Tests/*.swift`, `Support/MockTransport.swift` | 176 Tests (davon 5 in `DocumentationExamples.swift`). Portiere sie inhaltlich (gleiche Fälle, gleiche JSON-Fixtures, gleiche erwarteten URLs) |
| `Scripts/generate_docs.py` | Generator für die Referenz-Doku beider Clients, als Vorbild für ein Kotlin-Pendant |
| `AGENTS.md`, Abschnitt „Node64 – the local node API“ | 10 Node64-Regeln und 8 Rezepte |
| `docs/NODE64_API_REFERENCE.md`, `docs/NODE64_MODELS.md` | Alle 290 Node64-Endpunkte und -Modelle |
| `docs/NODE64_SPEC_GAPS.md` | Lücken der Node64-Spec und wie der Swift-Client sie löst |
| `Sources/IPv64/Node64/**` | `Node64.swift` (Client, Konfiguration), `Core/` (Fehler, Senden), `API/` (ein File je Bereich, `Namespaces.swift`), `Models/` |
| `Tests/IPv64Tests/Node64/*.swift` | 192 Node64-Tests (davon 3 in `Node64DocumentationExamples.swift`) |

Upstream IPv64: Spec `https://ipv64.net/api/v2/openapi.json` (OpenAPI 3.1, Quelle der Wahrheit), Doku `https://ipv64.net/api_v2_docs` (deutsch). Spec und Doku darfst du abrufen; lege die Spec als `spec/openapi.json` ins Repo, die Prüfskripte lesen sie von dort.

Upstream Node64: Die Spec liegt lokal unter `/Users/sebastianrank/Downloads/openapi.json` (Titel „Node64 – lokale API“, Version 1.2.0). Online steht sie hinter einem Login und ist nicht abrufbar. Kopiere sie als `spec/node64-openapi.json` ins Repo. Fehlt die Datei oder hat sie einen anderen Titel, frag mich. Die Spec nennt unter `servers` eine konkrete private Node (auch `docs/NODE64_SPEC_GAPS.md` des Swift-Packages zitiert sie). Ersetze die Adresse schon beim Kopieren durch `https://node.example.com/api` und übernimm sie nirgends in Code, Tests oder Doku.
Wenn Swift-Package und Spec sich widersprechen, gilt die Spec. Melde den Widerspruch im Abschlussbericht.
Ist der Swift-Pfad nicht lesbar, frag mich, bevor du ohne Vorlage anfängst.

## 2. Technische Vorgaben

- **Projekt:** Gradle (Kotlin DSL, Version Catalog `gradle/libs.versions.toml`, Gradle-Wrapper eingecheckt) in `/Programmierung/Android/IPv64-Package`, als lokales Git-Repo (kein Remote, kein Push). Das Library-Modul heißt `ipv64`, das Package `de.sr.ipv64api`, die Hauptklasse `IPv64`. `maven-publish` einrichten, damit `./gradlew publishToMavenLocal` funktioniert.
- **Toolchain:** Prüfe zuerst `java -version` (JDK 17+ nötig). Fehlen ein JDK oder ein `gradle` zum Erzeugen des Wrappers, frag mich, statt etwas zu installieren.
- **Modultyp:** Reines Kotlin/JVM-Library-Modul (`kotlin("jvm")` + `java-library`), keine Android-Abhängigkeit. Es läuft unverändert in Android-Apps und lässt sich ohne Emulator testen. Bytecode-Ziel Java 11: `kotlin { jvmToolchain(17); explicitApi(); compilerOptions { jvmTarget = JvmTarget.JVM_11; allWarningsAsErrors = true } }` und `tasks.withType<JavaCompile> { options.release = 11 }` (sonst bricht Gradles Prüfung auf gleiche JVM-Targets von Kotlin und Java ab).
- **Kern multiplattform-fähig halten:** Außer in `OkHttpTransport` nur Kotlin-stdlib und kotlinx im Kern: kein `java.*` (kein `java.time`, `java.net.URL`, `java.util.UUID`, kein `String.format`). Einzige Ausnahme ist der Default-Wert `OkHttpTransport()` in den Konstruktoren von `IPv64` und `Node64`; bei einem späteren Umstieg auf Kotlin Multiplatform wird daraus ein `expect`.
- **Abhängigkeiten** (jeweils die aktuelle **stabile** Version, prüfe sie beim Anlegen; keine Alphas oder RCs):
  - Aktuelles stabiles Kotlin mit gleich versioniertem Plugin `kotlin("plugin.serialization")`. Prüfe in den Release Notes, ob `kotlin.time.Instant` dort stabil ist (vermutlich ab 2.3). Falls nicht, setze `@OptIn(ExperimentalTime::class)` zentral per `compilerOptions.optIn` statt an jeder Datei und vermerke es im Bericht
  - `kotlinx-coroutines-core`: alle Endpunkte sind `suspend`
  - `kotlinx-serialization-json`: JSON
  - `okhttp` 5.x: Standard-Transport
  - **Kein** `kotlinx-datetime`: Zeitstempel sind `kotlin.time.Instant` aus der stdlib (läuft ohne Desugaring auf jedem minSdk). Falls du es doch brauchst: ab 0.7.1 ist `kotlinx.datetime.Instant` nur noch ein Typealias auf `kotlin.time.Instant`; in öffentlichen APIs immer `kotlin.time.Instant` importieren.
  - Test: JUnit 5 (`useJUnitPlatform()`, dazu `testRuntimeOnly("org.junit.platform:junit-platform-launcher")`), `kotlinx-coroutines-test`, `mockwebserver3` + `mockwebserver3-junit5` (nur für die Transport-Tests; das alte `mockwebserver` hängt an JUnit 4)
- **Kotlin-Stil:** Kotlin-Coding-Conventions, KDoc auf Englisch für alles Öffentliche, keine `!!` im Library-Code, kein `GlobalScope`, kein `runBlocking` im Library-Code. Opt-ins (`@OptIn(ExperimentalSerializationApi::class)` o. ä.) nur gezielt und mit Kommentar.
- **Android-Best-Practices:**
  - Alle `suspend`-Funktionen sind *main-safe*. `OkHttpTransport` nutzt `call.enqueue` + `suspendCancellableCoroutine`: Body in `onResponse` lesen (läuft auf OkHttps Dispatcher-Thread) und die `Response` schließen, `invokeOnCancellation { call.cancel() }`. So bricht Coroutine-Abbruch auch das Lesen des Bodys ab. **Nicht** `execute()` in `withContext(Dispatchers.IO)`: Ein blockierender Call reagiert nicht auf Cancellation. Das JSON-Decoding im Kern läuft in `withContext(Dispatchers.Default)`.
  - `OkHttpTransport()` ohne Argument nutzt einen einzigen, lazy erzeugten Default-`OkHttpClient`, nicht einen pro Instanz.
  - `IOException`s des Transports werden unverändert weitergeworfen (wie `URLError` in Swift), nicht in `IPv64Exception` verpackt.
  - Coroutine-Cancellation wird nie verschluckt. `CancellationException` wird immer weitergeworfen, auch in `catch`-Blöcken; kein `runCatching` um `suspend`-Aufrufe.
  - Den API-Key nie loggen. Falls du ein Logging-Interceptor-Beispiel zeigst, dann mit `redactHeader("Authorization")` und `redactHeader("X-API-Key")`.
  - R8/ProGuard: kotlinx.serialization bringt seine Regeln im JAR mit. Prüfe anhand der README von kotlinx.serialization (Abschnitt Android), ob die eigenen Klassen zusätzliche Regeln brauchen (Companion-Objekte mit Konstanten an `@Serializable`-Klassen beachten). Eigene Regeln gehören bei einem JVM-JAR nach `src/main/resources/META-INF/proguard/ipv64.pro` (R8 liest sie aus Abhängigkeits-JARs); `consumer-rules.pro`/`consumerProguardFiles` gibt es nur bei AARs. Ergebnis im README dokumentieren.

## 3. Abbildung Swift → Kotlin (verbindlich)

| Swift-Package | Kotlin |
|---|---|
| `public final class IPv64: Sendable` (unveränderlich) | `public class IPv64(configuration: Configuration, transport: IPv64Transport = OkHttpTransport())` plus Sekundärkonstruktor `(apiKey: String?, transport: IPv64Transport = OkHttpTransport())`. Unveränderlich, thread-safe |
| `IPv64.Configuration` (apiKey, authentication `.bearer`/`.apiKeyHeader`, baseURL, actAs, userAgent, timeoutInterval) | verschachtelt `IPv64.Configuration` (`data class`): `apiKey: String?`, `authentication = Authentication.BEARER`, `baseURL: String = PRODUCTION_BASE_URL`, `actAs: String? = null`, `userAgent = "IPv64-Kotlin/2.0"`, `timeout: Duration = 30.seconds`; `enum class Authentication { BEARER, API_KEY_HEADER }`. **`toString()` überschreiben**, sonst landet der API-Key in Logs |
| `ipv64.actingAs("…")` → neuer Client, Header `X-IPv64-Act-As` | gleich, `actingAs(account: String?)`; der neue Client teilt sich den Transport |
| `protocol IPv64Transport` | `fun interface IPv64Transport` mit eigenen, plattformneutralen Typen (siehe unten); Standard `OkHttpTransport(client: OkHttpClient = …)` |
| Namespaces `ipv64.domains`, `ipv64.cdn.mappings`, `ipv64.hc2.checks` … (Swift-Typen `IPv64.Domains`, `IPv64.CDN.Mappings`) | **identische Property-Namen**. Klassen flach benannt nach dem Swift-Typpfad + `API`: `DomainsAPI`, `CDNMappingsAPI`, `GatewaysPeersAPI`, `HC2ChecksAPI`, `ThreatWatchAPI` (verhindert Kollisionen wie `Records`/`CDN.Records`), jeweils `internal constructor(client: IPv64)`. Die 18 Bereiche sind Member-Properties von `IPv64` (`public val domains: DomainsAPI = DomainsAPI(this)`), verschachtelte sind Member der Elternklasse. Keine Extension-Properties: Die bräuchten beim Aufrufer einen Import |
| Methoden `list()`, `get(_:)`, `create(…)`, `update(_:…)` … | **identische Methodennamen**, `suspend`. Unbenannter erster Swift-Parameter (`_ token`) → positionaler Parameter mit dem internen Swift-Namen (`get(token: String)`). Labels → Parameternamen; weicht das Label vom internen Namen ab, gilt das Label (`feed(since, ifNoneMatch = etag)`). Swift-Defaults → Kotlin-Defaults. Überladungen wie in Swift; kollidieren sie auf der JVM, umbenennen und im Bericht melden |
| `async throws` → `IPv64Error` | wirft `IPv64Exception` (`sealed class … : Exception`): `API(problem)`, `HTTPStatus(code, body)`, `MissingAPIKey`, `InvalidResponse`, `InvalidRequest(reason)`, `Decoding(cause, body)`, `Encoding(cause)`. Alle als `class`, nicht `object` (Exceptions tragen Stacktrace und Suppressed-Liste). `message` wie Swifts `errorDescription`, Shortcuts `statusCode: Int?` und `code: String?`. In KDoc `@throws` dokumentieren; **kein** `@Throws` (suspend-Funktionen sind aus Java ohnehin kaum aufrufbar, Java-Interop ist kein Ziel) |
| `IPv64Problem` (RFC 9457) | `@Serializable data class IPv64Problem`, Pflichtfelder wie in Swift. `retryAfter` (`retry_after`) wird bei fehlendem Body-Feld aus dem `Retry-After`-Header gefüllt (nur ganze Sekunden, wie Swift) |
| Response-Hülle `{"data": …}` wird ausgepackt | gleich (interner `DataEnvelope<T>`). Ohne Hülle: `meta.openAPIDocument()` und `hc2.nodes.containers()` (beide `JsonElement`, leerer Body → `JsonNull`) |
| `IPv64Page<Item, Meta>` (`items` = JSON `data`, `meta`) | `data class IPv64Page<Item, Meta>(val items: List<Item>, val meta: Meta?)` |
| `IPv64OpenEnum` (String-Struct mit Konstanten, unbekannte Werte bleiben erhalten) | `@Serializable @JvmInline value class RecordType(public val value: String)` mit `override fun toString() = value` und `companion object { public val A: RecordType = RecordType("A") … }`. **Keine** `enum class` für Server-Werte: unbekannte Werte dürfen das Decodieren nicht brechen. Namensregel der Konstanten siehe unten |
| `CodingKeys` mit snake_case | `@SerialName("snake_case")` an jedem betroffenen Feld. Keine `JsonNamingStrategy`: Sie ist experimentell und macht aus Swift-Akronymen falsche Schlüssel (`domainID` → `domain_i_d`); explizite Namen kann das Prüfskript abgleichen |
| `Date` (ISO 8601 mit Offset, mit/ohne Sekundenbruchteile, reines Datum als Fallback) | `kotlin.time.Instant` mit eigenem `IPv64InstantSerializer`: `Instant.parse` (versteht `Z`, `+02:00` und Bruchteile), Fallback für `yyyy-MM-dd` → Mitternacht UTC (`Instant.parse("${s}T00:00:00Z")`). Encoding ohne Bruchteile (`Instant.fromEpochSeconds(i.epochSeconds).toString()` → `2026-10-10T10:00:00Z`), gleiches Format für Query-Werte. An **jedem** `Instant`-Feld `@Serializable(with = IPv64InstantSerializer::class)`, auch in Listen; der eingebaute Instant-Serializer von kotlinx.serialization darf nie greifen |
| `format: date` → `String` | `String` |
| `JSONValue` | `kotlinx.serialization.json.JsonElement` |
| Optionale Felder (`T?`) | nullable mit `= null`. **Nicht-null nur** für `id`/`token`/`nodeID`/`commandID` bzw. was in der Spec `required` und nicht nullable ist (gleiche Regel wie Swift, siehe `docs/MODELS.md`) |
| Swift `Int` (64 Bit) | `Int`; `Long` nur für Zähler, die 2³¹ überschreiten können (`traffic_bytes.in/out`, `queries_total`, `queries_blocked`, `pings_total` u. ä.; die Spec hat keine `format`-Angaben). Liste der `Long`-Felder in den Bericht |
| `…Input`-Structs mit Memberwise-Init | `@Serializable data class …Input` mit Default `null` für optionale Felder |
| PATCH sendet nur gesetzte Felder (`nil` wird weggelassen) | über die zentrale JSON-Konfiguration (unten): `null` wird weggelassen, `""` wird gesendet und löscht Werte, wo die API das vorsieht |
| `Path`-Interpolation encodiert Segmente | eigenes Percent-Encoding im Kern (UTF-8, Hex in Großbuchstaben), exakt wie Swift: Im Pfadsegment bleiben nur `A-Z a-z 0-9 - . _ ~ ! $ & ' ( ) * + , = : @` unkodiert. Erwartung aus `CoreTests`: `2001:db8::1` bleibt, `a/b?c#d e` → `a%2Fb%3Fc%23d%20e`. Kein `HttpUrl.Builder`: `addQueryParameter` kodiert `:` und `/`, die Swift-Tests erwarten sie roh |
| Query: `nil` fällt weg, `+` wird `%2B` | im Query-Wert bleiben `A-Z a-z 0-9 - . _ ~ ! $ ' ( ) * , ; : @ / ?` unkodiert; `&`, `=`, `+`, `#`, Leerzeichen und alles andere werden kodiert (`a&b=c d` → `a%26b%3Dc%20d`, `a+b` → `a%2Bb`). Ein abschließender `/` der Base-URL wird ignoriert |
| Multipart (Offline-Page-Icon) | Der Kern encodiert den Body selbst wie `MultipartFormData.swift` (Feld `icon`, Dateiname, Content-Type; Boundary über `kotlin.random.Random`) |
| `text/plain`-Antworten (WireGuard-Config, Passwort-Range) | `String`-Rückgabe, plus `passwordRangeEntries(prefix)` als geparste Variante |
| Conditional Threat-Feed (`If-None-Match`, 304 → `.notModified`) | `sealed interface ThreatFeedResult { data class Changed(val feed: ThreatFeed, val etag: String?); data object NotModified }`. 304 ist **nur** bei gesetztem `If-None-Match` ein Erfolg |
| `/node64/hello` sendet Header `X-Node64-Node` = `node_id` | gleich |
| Auth je Endpunkt: `.required` / `.optional` / `.none` | gleich (intern): `security: []` → kein Key und kein `X-IPv64-Act-As`; `[{}, bearer, apiKey]` → Key, falls vorhanden; sonst Pflicht, ohne Key `MissingAPIKey` **vor** dem Senden |

**Transport-Typen** (öffentlich, im Kern; keine `data class`, weil `ByteArray` keine Wertgleichheit hat):

```kotlin
public fun interface IPv64Transport { public suspend fun send(request: HTTPRequest): HTTPResponse } // lehnt der Compiler suspend in fun interface ab: normales interface
public class HTTPRequest(method: String, url: String, headers: Map<String, String>, body: ByteArray?, timeout: Duration)
public class HTTPResponse(statusCode: Int, headers: Map<String, String>, body: ByteArray) // + header(name): String?, case-insensitive
```

Der Kern liefert die fertig kodierte URL und alle Header inkl. `Content-Type` (JSON, Multipart oder roh); der Transport schickt nur Bytes. `OkHttpTransport` übernimmt die URL mit `toHttpUrl()` (bereits kodierte Sequenzen bleiben erhalten; per MockWebServer-Test die Request-Zeile prüfen) und setzt `timeout` als `call.timeout()`.

**Konstanten offener Enums: `UPPER_SNAKE_CASE`.** Die Kotlin-Conventions verlangen das für unveränderliche `val`s in Objekten, Kotlin-Entwickler erwarten es (`RecordType.AAAA`, `CloudRouterState.READY`), und es umgeht Schlüsselwort-Konflikte (Swift `` `default` `` → `DEFAULT`). Parität bleibt maschinell prüfbar, weil die Abbildung eine feste Regel ist: vor jedem Großbuchstaben, der auf einen Kleinbuchstaben oder eine Ziffer folgt, `_` einfügen, dann alles groß (`failoverRequested` → `FAILOVER_REQUESTED`, `invalidIP` → `INVALID_IP`, `httpAndHTTPS` → `HTTP_AND_HTTPS`, `last7Days` → `LAST7_DAYS`, `ipv64SMS` → `IPV64_SMS`). Dieselbe Regel gilt für `enum class Authentication`.

Zentrale JSON-Konfiguration: `Json { ignoreUnknownKeys = true; explicitNulls = false; encodeDefaults = true }`. Das entspricht genau Swift: Jeder Nicht-null-Wert wird gesendet, auch Defaults wie `schema = 1` im `HoneypotReport`; `null` lässt `explicitNulls = false` immer weg. Damit ist kein (experimentelles) `@EncodeDefault` nötig. Test: Ein PATCH mit einem Feld sendet genau einen Schlüssel.

## 4. Fachliche Entscheidungen, die du übernehmen musst

Diese Punkte hat das Swift-Package bereits gegen Spec und Doku geklärt. Lies jeweils den Swift-Code nach:

- **ID-Typen je Bereich**: siehe `AGENTS.md`, Regel 6. Domains, Records, Tokens u. a. sind `String`; API-Keys, Integrationen, Statusseiten, HC2-Kanäle/Wartungen u. a. sind `Int`.
- `include_secrets` wird als `Boolean` angeboten und als `"true"`/`"false"` gesendet.
- Das Feld `default` heißt `isDefault` (`@SerialName("default")`).
- `HoneypotReport.Sensor.id` ist ein `String`, kein `UUID`: Die Schreibweise muss exakt mit `report_id` übereinstimmen (Node64 sendet kleingeschrieben).
- `HC2Check.NodeReference` decodiert **beide** Formen: `{node_id, name}` und den reinen String (z. B. `JsonTransformingSerializer`, der den String in `{"node_id": …}` umformt).
- In Swift verschachtelte Modelltypen (`HoneypotReport.Sensor`, `HC2Check.NodeReference`) werden verschachtelte Klassen mit gleichem Namen.
- `HC2CheckDetail` und `HC2NodeDetail` (allOf) sind flache Typen. Gemeinsame verschachtelte Typen werden wiederverwendet, nicht dupliziert.
- Asynchrone Änderungen (202): Doku-Hinweise wie in Swift (`state == READY`, CDN `pending` leer, Failover-Status).
- `GET /node64/nodes` liefert rohes `JsonElement`, weil die Spec kein Schema angibt.
- Akronyme in **allen** Namen wie in Swift (`APIKey`, `CDNDomain`, `DNS64Client`, `HC2Check`, `PublicIP`, `ThreatIP`, `domainID`, `pendingDNS`, auch `HTTPRequest`, `MissingAPIKey`, `DomainsAPI`). In Kotlin ist das erlaubt und hält die Doku beider Plattformen deckungsgleich.

## 5. Zweiter Client: `Node64` (lokale Node-API)

`Node64` spricht die JSON-API einer einzelnen Node64-Node im eigenen Netz. Er nutzt denselben Kern wie `IPv64`: `IPv64Transport`/`OkHttpTransport`, Request-Bau, Percent-Encoding, `IPv64InstantSerializer`, Open-Enum-Muster, Multipart und die zentrale JSON-Konfiguration. Er hat aber eigene Konventionen. Lies vorher den Node64-Abschnitt in `AGENTS.md` und `Sources/IPv64/Node64/Node64.swift` sowie `Node64/Core/*`.

| Swift-Package | Kotlin |
|---|---|
| `public final class Node64: Sendable` mit `init(configuration:transport:)` und `init(baseURL:apiKey:transport:)` | `public class Node64` im Package `de.sr.ipv64api.node64`, Primärkonstruktor `(configuration, transport = OkHttpTransport())`, Sekundärkonstruktor `(baseURL: String, apiKey: String?, transport = OkHttpTransport())` |
| `Node64.Configuration` (baseURL **Pflicht**, apiKey, agentActor, userAgent `"IPv64-Swift/2.0 (Node64)"`, timeoutInterval 30) | `data class Configuration(baseURL: String, apiKey: String?, agentActor: String? = null, userAgent = "IPv64-Kotlin/2.0 (Node64)", timeout: Duration = 30.seconds)`, **`toString()` ohne API-Key**. Hinweis: Der Swift-Typ hat keine Redaktion, in Kotlin ist sie Pflicht, weil `data class` sonst alle Felder ausgibt |
| Modelle verschachtelt in `extension Node64 { … }` (`Node64.Check`, `Node64.APIKey`), damit sie nicht mit den ipv64.net-Modellen gleichen Namens kollidieren | **Package statt Verschachtelung:** Modelle liegen in `de.sr.ipv64api.node64.model` mit dem Swift-Namen ohne `Node64.`-Präfix (`Check`, `CheckInput`, `APIKey`). Tiefer verschachtelte Swift-Typen bleiben verschachtelte Klassen. Eine App, die beide Clients nutzt, löst Kollisionen per `import … as`; zeige das im README |
| Namespaces `node64.hc.checks`, `node64.dns64.groups.members`, `node64.hc.docker.systems` … | identische Property-Namen. Klassennamen = Swift-Typpfad **unterhalb** von `Node64` + `API`, im Package `de.sr.ipv64api.node64`: `HCAPI`, `HCChecksAPI`, `HCStatusPagesNoticesAPI`, `HCDockerSystemsAPI`, `HCProxmoxSystemsAPI`, `DNS64GroupsMembersAPI`, `Proxy64HoneypotAPI`, `HoneypotAPI`, `NodeModulesAPI`. Der volle Pfad verhindert die Kollisionen innerhalb von Node64 (`Honeypot` vs. `Proxy64.Honeypot`, `Docker.Systems` vs. `Proxmox.Systems`). Die 10 Bereiche (`node`, `hc`, `dyndns`, `dns64`, `proxy64`, `ports`, `certificates`, `link`, `cluster`, `honeypot`) sind Member-Properties von `Node64` |
| Fehler `Node64Error`: `.api(Node64APIError)`, `.httpStatus(code, body)`, `.missingAPIKey`, `.invalidResponse`, `.invalidRequest(String)`, `.decoding(error, body)`, `.encoding(error)`; Shortcuts `statusCode`, `code` (= `api.code ?? api.key`) | `sealed class Node64Exception : Exception` mit denselben Fällen als `class` (wie `IPv64Exception`), `message` wie Swifts `errorDescription` (bei `API`: `text ?: error ?: "HTTP status N"`) |
| `Node64APIError` (`status`, `error`, `field`, `fields`, `code`, `key`, `text`, `retryAfter`) | `data class Node64APIError`. `status` kommt aus dem HTTP-Status, `retryAfter` **nur** aus dem `Retry-After`-Header (ganze Sekunden, sonst `null`), nie aus dem Body. Der Body wird über eine interne `@Serializable`-DTO gelesen |
| Fehler-Mapping in `Node64+Send.swift` | exakt diese Reihenfolge: 2xx = Erfolg; 304 nur bei gesetztem `If-None-Match` ein Erfolg. Sonst Body als JSON-Objekt lesen: `API`, wenn `error`, `code` oder `text` gesetzt ist. Sonst bei 429 `API(Node64APIError(status = 429, retryAfter = …))` (429 ohne verwertbares Fehlerdokument, meist leerer Body). Sonst `HTTPStatus(code, body)`, auch bei Nicht-JSON-Bodys und Bodys nur mit `key`/`fields`. `IOException`s des Transports unverändert weiterwerfen |
| **Keine** `{"data": …}`-Hülle, Listen sind einfache JSON-Arrays, kein `IPv64Page` | gleich: `List<T>` direkt decodieren |
| Header: `Accept` je Request (Default `application/json`, **ohne** `application/problem+json`), `User-Agent`, `Authorization: Bearer <key>`, `X-Agent-Actor` nur wenn gesetzt und nur bei authentifizierten Requests | gleich |
| Auth: `.none` nur bei `GET /health`, `GET /push/{token}`, `POST /push/{token}`; alles andere `.required` (auch `/version`, `/metrics`) | gleich; `.none` sendet weder `Authorization` noch `X-Agent-Actor`, `.required` ohne Key wirft `MissingAPIKey` **vor** dem Senden |
| Sendevarianten `send<T>`, `sendWithoutContent`, `sendJSON` (leerer Body → `.null`), `sendText(accept:)`, `sendData(accept:)` | intern gleich benannt. `sendJSON` → `JsonElement` (leer → `JsonNull`), `sendText` → `String` (ungültiges UTF-8 → `Decoding`, z. B. `decodeToString(throwOnInvalidSequence = true)`), `sendData` → `ByteArray`. Leerer Body bei `send<T>` ist ein `Decoding`-Fehler. Die `Accept`-Werte je Endpunkt 1:1 aus den Swift-Quellen übernehmen (z. B. `application/vnd.sqlite3`, `application/x-pkcs12`, `application/x-apple-aspen-config`) |
| Methoden mit `JSONValue`-Rückgabe: die 14 aus `docs/NODE64_SPEC_GAPS.md`, Abschnitt 1 (u. a. `hc.checks.create/update`, `hc.maintenance.create/update`, `proxy64.status`; `certificates.acmeAuthorities.presets` als `[JSONValue]`), dazu `node.exportConfiguration` (die Exportdatei ist JSON) | `JsonElement` bzw. `List<JsonElement>`. **Nicht** eigenmächtig typisieren: Die Spec dokumentiert dort keine Antwort |
| Downloads als `Data` (`node.downloadDatabase`, `node.createBackup`, Zertifikats-Bundle, PKCS#12, CA-Datei `certificates.authorities.file`, DNS64-CA-Zertifikat, Mobileconfig, DNS64-Records-Export) | `ByteArray`. In KDoc als Geheimnis kennzeichnen (Backups und Schlüsselmaterial) |
| Bodys: JSON, Multipart (`certificates.upload`, Backup-Restore mit `file`/`password`), roh mit Content-Type (Statusseiten-Logo, DNS64-Records-Import `text/plain`, Restore `application/octet-stream`, Config-Import `application/json`) | gleich, über den gemeinsamen Kern |

**Sonderfälle, die du exakt nachbauen musst** (jeweils den Swift-Code und die Tests nachlesen):

- **PUT-Semantik je Endpunkt:** Node64 ändert per `PUT`, teils teilweise, teils als vollständiger Ersatz. Übernimm die Warnungen aus den Swift-Doc-Kommentaren wörtlich ins KDoc (siehe `AGENTS.md`, Node64-Regel 1). Besonders: `CheckInput.name` und `type` sind nicht-null **ohne** Default, `target: String?` hat **keinen** Default (der Aufrufer muss es bewusst setzen), und ein fehlendes `description` leert die Beschreibung auf dem Server.
- **`DynDNSCheckResult`:** `sealed interface` mit `Completed(status: DynDNSStatus)` und `data object Running`. `POST /dyndns/check` liefert bei 202 `Running`, sonst `Completed` mit dem decodierten Body.
- **`CertificateBundleResult`:** `Changed(data: ByteArray, etag: String?)` und `NotModified` (304 bei gesetztem `If-None-Match`). `Changed` als normale `class`, nicht `data class` (`ByteArray`).
- **Explizites `null`:** `PVESettingsInput.expectRunning` (`PVEExpectRunning`: `automatic`/`running`/`stopped`) (Body von `hc.docker.systems.updateSettings` und `hc.proxmox.systems.updateSettings`) ist die **einzige** Stelle, an der Node64 `null` sendet: `AUTOMATIC` → `"expect_running": null`, `RUNNING` → `true`, `STOPPED` → `false`, Feld `null` → Schlüssel fehlt. `explicitNulls = false` würde das `null` verschlucken, deshalb braucht `PVESettingsInput` einen eigenen `KSerializer`, der das `JsonObject` selbst baut. Mit Test für alle vier Fälle.
- **`hc.checks.types()`** (`GET /check-types`) decodiert nachsichtig wie in Swift: ein Array (oder `{"types": […]}`), dessen Einträge Strings oder Objekte sind (erster String aus `type`, `name`, `id`); nicht abbildbare Einträge fallen weg, alles andere ist ein `Decoding`-Fehler.
- **Push:** `hc.push(token, status, message)` ohne API-Key; Query `status` und `msg`; mit `payload` ein `POST` mit rohem Body (Content-Type Default `application/json`).
- **Zeitstempel:** Wo Swift `Date` nutzt, `Instant` mit `IPv64InstantSerializer`; wo Swift `String` nutzt (Spec ohne `format: date-time`, z. B. `Check.createdAt`, `CheckState.since`, `CheckEvent.time`), bleibt es `String`. Einige Felder sind Unix-Zeit in **Millisekunden** (`DNS64TimelineBucket.t`, `DNS64LogRow.t`, `Honeypot64Live.now`, `Honeypot64LiveEvent.t`): In Kotlin `Long` (in Swift ist `Int` 64 Bit). Wo Swift daraus `date` ableitet, wird es eine berechnete Property ohne Backing-Field.
- **`Long`-Felder:** Neben Epoch-Millisekunden alle Zähler und Größen, die 2³¹ überschreiten können (Bytes, Anfragen, Traffic, Dateigrößen). Liste in den Bericht.
- **ID-Typen:** gemischt `Int`/`String` je Endpunkt (`maintenance.update(id: Int)`, `checks.update(token: String)`). Immer die Swift-Signatur übernehmen.
- **Überladungen, die Swift nur über Labels trennt:** `node.restoreBackup(_ backup:, password:)` und `restoreBackup(file:filename:password:)` haben in Kotlin beide `(ByteArray, String…)`. Ein positionaler Aufruf `restoreBackup(bytes, "pw")` kann die Multipart-Variante wählen und das Passwort als Dateinamen senden. Prüfe das per Test; benenne die Multipart-Variante bei Bedarf um (z. B. `restoreBackupMultipart`) und melde es im Bericht.
- **Pfadwerte mit `/`** (z. B. IPv6-`/64` in `DELETE /cdn64/limits/bans/{ip}`) werden als `%2F` kodiert, wie im gemeinsamen Kern.
- Offene Enums (96 Typen) und 3 echte Swift-Enums (`DynDNSCheckResult`, `CertificateBundleResult`, `PVEExpectRunning`): offene Enums als `value class` wie bei `IPv64`; `PVEExpectRunning` ist ein reiner Client-Wert und darf eine `enum class` sein.

**Ablauf für Node64** (nach Abschluss von `IPv64`, Schritte wie in Abschnitt 6):

1. **Kern selbst bauen:** `Node64`, `Configuration`, `Node64Exception`/`Node64APIError`, Fehler-Mapping, Sendevarianten, alle leeren Namespace-Klassen samt Properties, dazu der Bereich `node` aus `Node64/API/Node.swift` (`health`, `version`, `metrics`). Portiere `Node64CoreTests`. Committen, wenn grün.
2. **Bereiche parallel mit Subagenten** in eigenen Worktrees, in derselben Aufteilung wie beim Swift-Package (Zahl = Endpunkte der Spec, zusammen 290). Der Brief verweist zusätzlich auf diesen Abschnitt 5 und ordnet **jede** Swift-Datei unter `Node64/Models/**` genau einer Gruppe zu (keine Modelldatei wird von zwei Gruppen gebraucht):
   - N1: Node-Verwaltung, Backup, Module, API-Keys, Verknüpfung, Cluster (47)
   - N2: DynDNS, Honeypot64, Benachrichtigungskanäle (30)
   - N3: Healthchecks-Kern: Checks, Events, Incidents, Wartung, Push, Online-Checks (31)
   - N4: Statusseiten, Docker, Proxmox (33)
   - N5: DNS64-Kern: Status, Listen, Upstreams, Cache, Allowlist, Records (31)
   - N6: DNS64-Gruppen, Geräte, Forwards, Rewrites, Zonen (37)
   - N7: PROXY64 (45)
   - N8: Ports, Edge, Zertifikate, CAs, ACME (36)
3. **Prüfskripte** wie bei `IPv64`, gegen `spec/node64-openapi.json`: Abdeckung **290/290**, `@SerialName`-Abgleich, Parität mit `docs/NODE64_API_REFERENCE.md`. Die Node64-Spec hat keine `operationId`s; Swift-Methodennamen sind deshalb die einzige Namensquelle. Zwei Abweichungen zwischen Spec und Swift-Doc-Zeilen muss das Skript kennen: `hc.onlineChecks.pause/resume/run` sind Komfortmethoden für `POST /online-checks/{token}/{action}` (eigene Pfade, die die Spec nicht hat), und `hc.push` deckt `GET` und `POST /push/{token}` ab; im Index von `docs/NODE64_API_REFERENCE.md` fehlt deshalb `POST /push/{token}`.

## 6. Vorgehen

1. **Kern zuerst, selbst bauen:** Gradle-Setup, `IPv64`, Konfiguration, Transport-Typen + `OkHttpTransport`, Request-Bau (Pfad/Query/Header/Auth/Act-As), Fehler-Mapping, `IPv64InstantSerializer`, Open-Enum-Muster, `IPv64Page`, Multipart, dazu `Meta` als Referenzbereich. Lege außerdem für alle 18 Bereiche die leeren Namespace-Klassen samt Property in `IPv64` an und portiere bereichsübergreifende Modelle (`Models/Shared/Record.swift`, `IPFamily` u. a.). Portiere `CoreTests`, `MetaTests` und `ConditionalRequestTests`. Erst wenn das kompiliert und grün ist, committen und weiter.
2. **Brief für die Bereiche** schreiben: Verweis auf Abschnitt 3 und 4, Dateilayout (`api/<Bereich>.kt`, `model/<bereich>/…` analog zu den Swift-Ordnern, Tests `<Bereich>Test.kt`), und eine Zuordnung **jeder** Swift-Modelldatei zu genau einem Agenten. Danach die Bereiche **parallel mit Subagenten** umsetzen, in derselben Aufteilung wie beim Swift-Package (Zahl = Endpunkte):
   - A: Account, API-Keys, Domains, DynDNS, DNS-Records, Benachrichtigungen (26)
   - B: Healthchecks, DNS-Failover, Statusseiten, Offline-Pages (37)
   - C: CDN, DNS64 (31)
   - D: Cloud Router, Gateways, Peers (39)
   - E: Healthchecks 2.0, Nodes (43)
   - F: Honeypot64, Threat (12)

   Jeder Agent portiert die zugehörigen Swift-Tests und arbeitet in einem eigenen Git-Worktree (Agent-Tool mit `isolation: "worktree"`), ändert nur die ihm zugeordneten Dateien und verifiziert dort mit `./gradlew :ipv64:test`. Danach führst du die Worktrees zusammen und baust komplett.
3. **Abdeckung maschinell prüfen:** Ein Skript gleicht jede Operation der `spec/openapi.json` (Methode + Pfad) gegen die Kotlin-Quellen ab. Das Ziel ist **192/192**. Ein zweites Skript vergleicht je Modell die `@SerialName`-Werte und Typen mit den Schema-Properties (Tippfehler bei JSON-Schlüsseln sind das Hauptrisiko) und meldet `Instant`-Felder ohne `IPv64InstantSerializer`.
4. **Parität mit Swift prüfen:** Ein Skript erzeugt aus `docs/API_REFERENCE.md` (Swift) und deiner Kotlin-Referenz eine Tabelle Endpunkt → Swift-Aufruf → Kotlin-Aufruf und vergleicht die Enum-Konstanten aus `docs/MODELS.md` über die Namensregel. Pfad und Methodenname müssen pro Endpunkt übereinstimmen; Abweichungen nur mit Begründung.
5. **Review** durch einen separaten Agenten: Spec-Treue, Coroutine-Korrektheit (Cancellation, Main-Safety, keine verschluckten `CancellationException`s), öffentliche API (`explicitApi`, nichts Internes sichtbar, kein API-Key in `toString`), Test-Qualität.

## 7. Dokumentation (für Menschen und KI-Agenten)

Lege dieselbe Doku-Struktur an wie im Swift-Package:

- `README.md` (deutsch): Installation (`includeBuild` / `mavenLocal()` / später Maven Central oder JitPack), Schnellstart, Bereiche, Konfiguration, `actingAs`, Fehler, Paging, 202-Polling, offene Enums, PATCH-Semantik, eigener Transport, R8. Dazu oben ein Abschnitt „Für KI-Agenten“, der auf `AGENTS.md` verweist.
- `AGENTS.md` (englisch): Kotlin-Pendant zum Swift-`AGENTS.md`, mit denselben 12 Regeln in Kotlin-Formulierung (z. B. `?:`/`?.let` statt `!!`, `when` mit `else` bei offenen Enums) und denselben 13 Rezepten in Kotlin. Zusätzlich Android-Rezepte:
  - Client per DI bereitstellen (Hilt-Modul mit `@Provides @Singleton` *oder* manuell als Singleton in der `Application`)
  - Aufruf aus einem `ViewModel` mit `viewModelScope` und `StateFlow`-UI-State
  - Periodisches DynDNS-Update per `WorkManager` (`CoroutineWorker`, `PeriodicWorkRequest` mit mindestens 15 Minuten, Constraint `NetworkType.CONNECTED`, `Result.retry()` bei `IOException`/429)
  - API-Key sicher speichern: AES-GCM-Schlüssel im Android Keystore, Chiffrat in DataStore (oder Tink). `EncryptedSharedPreferences`/`security-crypto` ist deprecated und hat keinen offiziellen Nachfolger; keine Klartext-Prefs
- `docs/API_REFERENCE.md` und `docs/MODELS.md`: **aus dem Kotlin-Code generiert** (Skript im Repo, z. B. `scripts/generate_docs.py`), gleiches Format wie beim Swift-Package, damit ein Agent nach `PATCH /records/{record}` suchen kann.
- **Rezepte kompilieren:** Alle Rezepte stehen zusätzlich als Code im Test-Source-Set (`DocumentationExamples.kt`). Die Hilfsfunktionen (Retry, Polling, Stub-Transport) werden auch ausgeführt. Die Android-spezifischen Rezepte (Hilt, ViewModel, WorkManager, Keystore) bleiben reine Doku-Snippets, weil das Modul keine Android-Abhängigkeit hat. Kennzeichne sie als nicht kompiliert.
- **Node64:**
  - In `AGENTS.md` ein eigener Abschnitt „Node64 – the local node API“ mit denselben 10 Regeln und 8 Rezepten wie im Swift-Package. Die Rezepte stehen kompiliert in `Node64DocumentationExamples.kt`, die 3 ausgeführten Swift-Rezepttests werden portiert.
  - `docs/NODE64_API_REFERENCE.md` und `docs/NODE64_MODELS.md` erzeugt derselbe Generator.
  - Übernimm `docs/NODE64_SPEC_GAPS.md` mit Kotlin-Aufrufen, aber ohne die private Node-Adresse aus dem `servers`-Hinweis. Lücken, die du zusätzlich findest, ergänzt du dort.
  - README-Abschnitt „Node64“ mit Beispiel, Bereichstabelle und den Unterschieden zu `IPv64`.
  - Android-Rezept (nicht kompiliert) **Node im lokalen Netz erreichen:**
    - Klartext-HTTP nur per Network Security Config mit `domain-config` für den Host der Node erlauben, nie global per `base-config`. Prüfe, ob `<domain>` auch reine IP-Adressen abdeckt, und dokumentiere das Ergebnis.
    - Selbstsignierte Zertifikate per `trust-anchors` mit der CA der Node oder per eigenem `OkHttpClient` (nur für `Node64`) mit `HandshakeCertificates` (okhttp-tls) vertrauen, beschränkt auf diese CA. **Nie** einen Trust-all-`TrustManager` und nie einen `hostnameVerifier`, der alles akzeptiert; das Zertifikat muss Hostname bzw. IP der Node enthalten.
    - Prüfe, ob aktuelle Android-Versionen für Zugriffe ins lokale Netz eine Laufzeitberechtigung verlangen (Stichwort „local network protection“, `ACCESS_LOCAL_NETWORK`), und dokumentiere den Stand mit Quelle.
  - Android-Rezept (nicht kompiliert) **Backup sichern:** `node.downloadDatabase()` per Storage Access Framework (`ActivityResultContracts.CreateDocument`) an einen vom Nutzer gewählten Ort schreiben, nicht in öffentlichen Speicher. Dazu der Hinweis, dass die Datei alle Geheimnisse der Node enthält.

## 8. Abnahmekriterien

- `./gradlew build` ohne Fehler und ohne Compiler-Warnungen (`allWarningsAsErrors`); alle Tests grün, zu jedem der 368 Swift-Tests ein Kotlin-Pendant (176 `IPv64`, 192 `Node64`).
- Abdeckung 192/192 (`IPv64`) und 290/290 (`Node64`), JSON-Schlüssel-Abgleich ohne Abweichungen für beide Clients, Parität mit Swift dokumentiert.
- Keine `!!`, kein `runBlocking`, kein `GlobalScope` im Library-Code; `explicitApi()` aktiv.
- `./gradlew publishToMavenLocal` funktioniert; das README zeigt die Einbindung in eine Android-App. Ein App-Modul ist nicht nötig (es bräuchte das Android SDK).
- Abschlussbericht (deutsch, knapp): Projektstruktur, Abweichungen vom Swift-Package mit Begründung, `Long`-Felder, Widersprüche Spec ↔ Swift, offene Punkte. Alles getrennt nach `IPv64` und `Node64`.

Versions- und Bibliotheksdetails in diesem Auftrag (OkHttp-Encoding, `toHttpUrl()`, R8-Regeln, Artefaktnamen) stammen teils aus dem Gedächtnis. Prüfe sie per Test oder Doku, bevor du dich darauf verlässt, und korrigiere den Ansatz, wenn sie nicht stimmen.

Keine echten API-Aufrufe gegen ipv64.net oder eine Node64-Node ohne meine ausdrückliche Zustimmung (das Abrufen von Spec und Doku von ipv64.net ist erlaubt). Getestet wird mit Stub-Transport bzw. MockWebServer.
