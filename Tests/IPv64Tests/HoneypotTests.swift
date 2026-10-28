import Foundation
import Testing
@testable import IPv64

@Suite("Honeypot")
struct HoneypotTests {
    @Test("POST /honeypot/reports encodes the report")
    func submit() async throws {
        let sensorID = "1b4e28ba-2fa1-11d2-883f-0016d3cca427"
        let start = Date(timeIntervalSince1970: 1_791_626_400)
        let report = HoneypotReport(
            reportID: "\(sensorID)-1791626400",
            sensor: .init(id: sensorID, version: "1.0.0", profile: .standard, mode: .module),
            period: .init(start: start, end: start.addingTimeInterval(3600)),
            sources: [
                .init(ip: "203.0.113.7", kind: "ssh:bruteforce", service: "ssh", port: 22, count: 3,
                      first: start, last: start.addingTimeInterval(60), source: .honeypot, rule: "honeypot/ssh@1")
            ],
            samples: .init(
                credentials: [.init(service: "ssh", user: "root", pass: "toor", count: 2)],
                userAgents: [.init(key: "curl/8", count: 1)]
            )
        )
        let transport = MockTransport(status: 202, json: """
        {"data":{"accepted":1,"rejected":0,"rejected_reasons":{},"report_id":"abc"}}
        """)
        let result = try await IPv64.mock(transport).honeypot.submitReport(report)

        #expect(result.accepted == 1)
        #expect(result.duplicate == nil)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/honeypot/reports")
        guard case .object(let body)? = request.jsonBody else {
            Issue.record("Expected a JSON object")
            return
        }
        #expect(body["schema"] == .number(1))
        #expect(body["report_id"] == .string("1b4e28ba-2fa1-11d2-883f-0016d3cca427-1791626400"))
        #expect(body["dropped"] == nil)
        #expect(body["period"] == .object([
            "start": .string("2026-10-10T10:00:00Z"), "end": .string("2026-10-10T11:00:00Z"),
        ]))
        guard case .object(let sensor)? = body["sensor"] else {
            Issue.record("Expected sensor object")
            return
        }
        #expect(sensor["id"] == .string("1b4e28ba-2fa1-11d2-883f-0016d3cca427"))
        #expect(sensor["profile"] == .string("standard"))
        #expect(sensor["mode"] == .string("module"))
        guard case .object(let samples)? = body["samples"] else {
            Issue.record("Expected samples object")
            return
        }
        #expect(samples["user_agents"] != nil)
        #expect(samples["credentials"] != nil)
        #expect(samples["paths"] == nil)
        guard case .array(let sources)? = body["sources"], case .object(let source)? = sources.first else {
            Issue.record("Expected sources")
            return
        }
        #expect(source["source"] == .string("honeypot"))
        #expect(source["port"] == .number(22))
    }

    @Test("POST /honeypot/reports decodes the duplicate response")
    func duplicate() async throws {
        let transport = MockTransport(json: #"{"data":{"duplicate":true,"report_id":"abc"}}"#)
        let report = HoneypotReport(
            reportID: "abc",
            sensor: .init(id: "1b4e28ba-2fa1-11d2-883f-0016d3cca427", version: "1", profile: .full, mode: .headless),
            period: .init(start: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 60)),
            sources: []
        )
        let result = try await IPv64.mock(transport).honeypot.submitReport(report)
        #expect(result.duplicate == true)
        #expect(result.reportID == "abc")
    }

    @Test("GET /honeypot/sensors decodes sensors")
    func sensors() async throws {
        let transport = MockTransport(json: """
        {"data":[{"id":"11111111-2222-3333-4444-555555555555","version":"1.0.0","profile":"standard","mode":"module",
        "first_seen":"2026-10-01T10:00:00Z","last_seen":"2026-10-20T12:00:00Z","online":true,"reports":40,
        "disabled":false,"sources_24h":5,"sources_7d":20,"events_24h":100,"events_7d":700}]}
        """)
        let sensors = try await IPv64.mock(transport).honeypot.sensors()

        let sensor = try #require(sensors.first)
        #expect(sensor.id == "11111111-2222-3333-4444-555555555555")
        #expect(sensor.online == true)
        #expect(sensor.events7d == 700)
        #expect(transport.lastRequest?.relativePath == "/honeypot/sensors")
    }

    @Test("GET /honeypot/stats decodes the contribution")
    func stats() async throws {
        let transport = MockTransport(json: """
        {"data":{"sensors":2,"sensors_online":1,"contributor":true,"last_report":null,"events_24h":10,"events_7d":70,
        "sources_24h":3,"sources_7d":9,"top_kinds":[{"kind":"ssh:bruteforce","events":9,"sources":2}],
        "top_ports":[{"service":"ssh","port":22,"events":9,"sources":2}],
        "timeline":[{"day":"2026-10-19","events":10}]}}
        """)
        let stats = try await IPv64.mock(transport).honeypot.stats()

        #expect(stats.contributor == true)
        #expect(stats.lastReport == nil)
        #expect(stats.topPorts?.first?.port == 22)
        #expect(stats.timeline?.first?.day == "2026-10-19")
    }

    @Test("Honeypot errors surface the problem code")
    func rateLimited() async throws {
        let transport = MockTransport(status: 429, json: """
        {"type":"about:blank","title":"Too Many Requests","status":429,"detail":"Slow down","code":"rate_limited","retry_after":120}
        """)
        do {
            _ = try await IPv64.mock(transport).honeypot.stats()
            Issue.record("Expected an error")
        } catch let error as IPv64Error {
            #expect(error.code == "rate_limited")
            #expect(error.statusCode == 429)
        }
    }
}
