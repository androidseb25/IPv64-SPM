import Foundation
import Testing
@testable import IPv64

@Suite("OfflinePages")
struct OfflinePagesTests {
    static let pageJSON = """
    {"id":"aB3dE6gH9jK2mN5p","name":"Wartungsarbeiten","domain":"www.example.com","email":"info@example.com",
     "phone":"+49301234567","alternative_url":"https://status.example.com","text":"Wir sind gleich wieder da.",
     "icon_url":null,"views":0,"in_use_by_policy":null,"active":false,
     "preview_url":"https://ipv64.net/offline?domain=www.example.com&preview"}
    """

    @Test("OfflinePage schema decodes")
    func decode() throws {
        let page = try IPv64Coding.makeDecoder().decode(OfflinePage.self, from: Data(Self.pageJSON.utf8))
        #expect(page.id == "aB3dE6gH9jK2mN5p")
        #expect(page.alternativeURL == "https://status.example.com")
        #expect(page.iconURL == nil)
        #expect(page.inUseByPolicy == nil)
        #expect(page.active == false)
        #expect(page.previewURL?.hasSuffix("&preview") == true)
    }

    @Test("create and update send the input as JSON")
    func createUpdate() async throws {
        let transport = MockTransport(status: 201, json: #"{"data":\#(Self.pageJSON)}"#)
        let api = IPv64.mock(transport).offlinePages
        _ = try await api.create(OfflinePageInput(name: "Wartungsarbeiten", domain: "www.example.com", alternativeURL: "https://x.test"))
        #expect(transport.lastRequest?.httpMethod == "POST")
        #expect(transport.lastRequest?.relativePath == "/offline-pages")
        #expect(transport.lastRequest?.jsonBody == .object([
            "name": "Wartungsarbeiten", "domain": "www.example.com", "alternative_url": "https://x.test",
        ]))

        _ = try await api.update("aB3dE6gH9jK2mN5p", OfflinePageInput(text: "Wartung bis 14 Uhr."))
        #expect(transport.lastRequest?.httpMethod == "PATCH")
        #expect(transport.lastRequest?.relativePath == "/offline-pages/aB3dE6gH9jK2mN5p")
        #expect(transport.lastRequest?.jsonBody == .object(["text": "Wartung bis 14 Uhr."]))
    }

    @Test("list, get, delete and deleteIcon")
    func listGetDelete() async throws {
        let transport = MockTransport(json: #"{"data":[\#(Self.pageJSON)]}"#)
        #expect(try await IPv64.mock(transport).offlinePages.list().count == 1)

        let getTransport = MockTransport(json: #"{"data":\#(Self.pageJSON)}"#)
        _ = try await IPv64.mock(getTransport).offlinePages.get("x")
        #expect(getTransport.lastRequest?.relativePath == "/offline-pages/x")

        let deleteTransport = MockTransport(status: 204)
        let api = IPv64.mock(deleteTransport).offlinePages
        try await api.delete("x")
        try await api.deleteIcon("x")
        #expect(deleteTransport.requests.map(\.relativePath) == ["/offline-pages/x", "/offline-pages/x/icon"])
        #expect(deleteTransport.requests.allSatisfy { $0.httpMethod == "DELETE" })
    }

    @Test("uploadIcon sends multipart/form-data with filename and image bytes")
    func uploadIcon() async throws {
        let transport = MockTransport(json: #"{"data":\#(Self.pageJSON)}"#)
        let image = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0xDE, 0xAD, 0xBE, 0xEF])
        _ = try await IPv64.mock(transport).offlinePages.uploadIcon(
            "aB3dE6gH9jK2mN5p", imageData: image, filename: "logo.png", contentType: "image/png"
        )
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.relativePath == "/offline-pages/aB3dE6gH9jK2mN5p/icon")

        let contentType = try #require(request.value(forHTTPHeaderField: "Content-Type"))
        #expect(contentType.hasPrefix("multipart/form-data; boundary="))
        let boundary = String(contentType.dropFirst("multipart/form-data; boundary=".count))
        #expect(!boundary.isEmpty)

        let body = try #require(request.httpBody)
        let text = String(decoding: body, as: UTF8.self)
        #expect(text.contains("--\(boundary)\r\n"))
        #expect(text.contains(#"name="icon"; filename="logo.png""#))
        #expect(text.contains("Content-Type: image/png"))
        #expect(text.hasSuffix("--\(boundary)--\r\n"))
        #expect(body.range(of: image) != nil)
    }

    @Test("413 problem+json becomes IPv64Error.api")
    func tooLarge() async throws {
        let transport = MockTransport(status: 413, json: """
        {"type":"https://ipv64.net/api/v2/errors#payload_too_large","title":"Payload Too Large","status":413,
         "detail":"Max 1 MB.","code":"payload_too_large"}
        """)
        do {
            _ = try await IPv64.mock(transport).offlinePages.uploadIcon("x", imageData: Data([1]), filename: "a.png", contentType: "image/png")
            Issue.record("Expected an error")
        } catch let IPv64Error.api(problem) {
            #expect(problem.code == "payload_too_large")
        }
    }
}
