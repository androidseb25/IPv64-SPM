import Foundation
import Testing
@testable import IPv64

@Suite("Node64 certificates")
struct Node64CertificatesTests {
    private let certJSON = """
    {"id":7,"names":["home.ipv64.de","*.home.ipv64.de"],"source":"ipv64","staging":false,"auto_renew":true,
     "status":"valid","issuer":"R11","not_before":"2026-10-01T00:00:00Z","not_after":"2026-12-30T00:00:00Z",
     "used_by":["proxy64"],"created_at":"2026-10-01T00:00:00Z","updated_at":"2026-10-01T00:00:00Z",
     "acme_ca":0,"key_type":"ecdsa","dns_account":3,"ca_id":2,"days":397}
    """

    @Test("Certificate decodes")
    func decodeCertificate() async throws {
        let transport = MockTransport(json: "[\(certJSON)]")

        let list = try await Node64.mock(transport).certificates.list()

        let cert = try #require(list.first)
        #expect(cert.id == 7)
        #expect(cert.source == .ipv64)
        #expect(cert.status == .valid)
        #expect(cert.autoRenew == true)
        #expect(cert.keyType == .ecdsa)
        #expect(cert.notAfter == Date(timeIntervalSince1970: 1_798_588_800))
        #expect(cert.acmeCA == 0)
        #expect(transport.lastRequest?.nodeRelativePath == "/certs")
    }

    @Test("Create sends the input as JSON")
    func create() async throws {
        let transport = MockTransport(status: 202, json: certJSON)

        _ = try await Node64.mock(transport).certificates.create(
            .init(names: ["nas.lan"], source: .ca, caID: 2, days: 90)
        )

        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.nodeRelativePath == "/certs")
        #expect(request.jsonBody == .object([
            "names": .array([.string("nas.lan")]), "source": .string("ca"),
            "ca_id": .number(2), "days": .number(90),
        ]))
    }

    @Test("Upload as JSON and as multipart")
    func upload() async throws {
        let transport = MockTransport(status: 201, json: certJSON)
        let node = Node64.mock(transport)

        _ = try await node.certificates.upload(.init(cert: "CERT", key: "KEY", password: "pw"))
        #expect(transport.lastRequest?.jsonBody == .object([
            "cert": .string("CERT"), "key": .string("KEY"), "password": .string("pw"),
        ]))

        _ = try await node.certificates.upload(certFile: Data("CERT".utf8), keyFile: Data("KEY".utf8), keyPassword: "pw")
        let request = try #require(transport.lastRequest)
        #expect(request.nodeRelativePath == "/certs/upload")
        #expect(request.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("multipart/form-data; boundary=") == true)
        let body = String(decoding: request.httpBody ?? Data(), as: UTF8.self)
        #expect(body.contains("name=\"cert_file\""))
        #expect(body.contains("name=\"key_file\""))
        #expect(body.contains("name=\"key_password\""))
    }

    @Test("Update, delete with force and renew build the right requests")
    func updateDeleteRenew() async throws {
        let transport = MockTransport(json: certJSON)
        let node = Node64.mock(transport)

        _ = try await node.certificates.update(7, autoRenew: false)
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.jsonBody == .object(["auto_renew": .bool(false)]))

        _ = try await node.certificates.renew(7)
        #expect(transport.lastRequest?.nodeRelativePath == "/certs/7/renew")

        let deleteTransport = MockTransport(status: 204, body: Data())
        try await Node64.mock(deleteTransport).certificates.delete(7, force: true)
        #expect(deleteTransport.lastRequest?.httpMethod == "DELETE")
        #expect(deleteTransport.lastRequest?.nodeRelativePath == "/certs/7?force=1")
    }

    @Test("Chain returns PEM text")
    func chain() async throws {
        let transport = MockTransport(status: 200, body: Data("-----BEGIN CERTIFICATE-----".utf8))

        let pem = try await Node64.mock(transport).certificates.chain(7)

        #expect(pem == "-----BEGIN CERTIFICATE-----")
        #expect(transport.lastRequest?.value(forHTTPHeaderField: "Accept") == "application/pem-certificate-chain")
    }

    @Test("Meta decodes")
    func meta() async throws {
        let transport = MockTransport(json: """
        {"id":7,"names":["a.lan"],"issuer":"R11","serial":"0a1b","not_before":"2026-10-01T00:00:00Z",
         "not_after":"2026-12-30T00:00:00Z","days_left":64,"fingerprint_sha256":"ab12"}
        """)

        let meta = try await Node64.mock(transport).certificates.meta(7)

        #expect(meta.daysLeft == 64)
        #expect(meta.fingerprintSHA256 == "ab12")
        #expect(transport.lastRequest?.nodeRelativePath == "/certs/7/meta")
    }

    @Test("Bundle download returns the file")
    func bundleData() async throws {
        let zip = Data([0x50, 0x4B, 0x03, 0x04])
        let transport = MockTransport(status: 200, body: zip, headers: ["Content-Type": "application/zip"])

        let data = try await Node64.mock(transport).certificates.bundle(7, format: .zip)

        #expect(data == zip)
        #expect(transport.lastRequest?.nodeRelativePath == "/certs/7/bundle?format=zip")
    }

    @Test("Conditional bundle returns changed with ETag and notModified on 304")
    func bundleConditional() async throws {
        let pem = Data("PEM".utf8)
        let changedTransport = MockTransport(status: 200, body: pem, headers: ["ETag": "\"abc\"", "Content-Type": "application/x-pem-file"])

        let changed = try await Node64.mock(changedTransport).certificates.bundle(7, format: .fullchain, ifNoneMatch: "\"old\"")

        #expect(changed == .changed(pem, etag: "\"abc\""))
        #expect(changedTransport.lastRequest?.value(forHTTPHeaderField: "If-None-Match") == "\"old\"")

        let notModifiedTransport = MockTransport(status: 304, body: Data())
        let unchanged = try await Node64.mock(notModifiedTransport).certificates.bundle(7, ifNoneMatch: "\"abc\"")
        #expect(unchanged == .notModified)
    }

    @Test("P12 posts the password and returns the file")
    func p12() async throws {
        let file = Data([0x30, 0x82])
        let transport = MockTransport(status: 200, body: file, headers: ["Content-Type": "application/x-pkcs12"])

        let data = try await Node64.mock(transport).certificates.p12(7, password: "secret", legacy: true)

        #expect(data == file)
        let request = try #require(transport.lastRequest)
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/x-pkcs12")
        #expect(request.jsonBody == .object(["password": .string("secret"), "legacy": .bool(true)]))
    }

    @Test("ACME account decodes and update sends accept_tos")
    func account() async throws {
        let transport = MockTransport(json: #"{"email":"a@b.de","tos_accepted":true,"tos_at":"2026-10-01T00:00:00Z","tos_url":"https://le.org/tos"}"#)

        let account = try await Node64.mock(transport).certificates.account.update(email: "a@b.de", acceptTOS: true)

        #expect(account.tosAccepted == true)
        #expect(account.tosURL == "https://le.org/tos")
        #expect(transport.lastRequest?.nodeRelativePath == "/certs/account")
        #expect(transport.lastRequest?.jsonBody == .object(["email": .string("a@b.de"), "accept_tos": .bool(true)]))
    }

    @Test("DNS providers and accounts")
    func dns() async throws {
        let providers = MockTransport(json: """
        [{"id":"cloudflare","name":"Cloudflare","docs":"https://x","fields":[{"key":"token","label":"Token","secret":true,"optional":false,"default":"x"}]}]
        """)
        let list = try await Node64.mock(providers).certificates.dnsProviders()
        #expect(list.first?.id == "cloudflare")
        #expect(list.first?.fields?.first?.secret == true)
        #expect(list.first?.fields?.first?.default == "x")

        let accounts = MockTransport(status: 201, json: """
        {"id":3,"name":"CF","provider":"cloudflare","provider_name":"Cloudflare","values":{"token":"set"},"used_by":[],
         "created_at":"2026-10-01T00:00:00Z","updated_at":"2026-10-01T00:00:00Z"}
        """)
        let account = try await Node64.mock(accounts).certificates.dnsAccounts.create(
            name: "CF", provider: "cloudflare", values: ["token": "abc"]
        )
        #expect(account.providerName == "Cloudflare")
        #expect(account.values?["token"] == "set")
        #expect(accounts.lastRequest?.jsonBody == .object([
            "name": .string("CF"), "provider": .string("cloudflare"), "values": .object(["token": .string("abc")]),
        ]))
    }

    @Test("Own CAs decode, import and file download")
    func authorities() async throws {
        let transport = MockTransport(json: """
        {"id":2,"name":"Home CA","subject":"CN=Home CA","not_after":"2036-10-01T00:00:00Z","imported":false,"root":true,
         "permitted_dns":[".lan"],"permitted_ip":["192.168.0.0/16"],"fingerprint_sha256":"ff","certificates":1,
         "created_at":"2026-10-01T00:00:00Z"}
        """)
        let node = Node64.mock(transport)

        let authority = try await node.certificates.authorities.create(name: "Home CA", keyType: .rsa, domains: ["home.test"])
        #expect(authority.permittedDNS == [".lan"])
        #expect(authority.fingerprintSHA256 == "ff")
        #expect(transport.lastRequest?.jsonBody == .object([
            "name": .string("Home CA"), "key_type": .string("rsa"), "domains": .array([.string("home.test")]),
        ]))

        _ = try await node.certificates.authorities.rename(2, to: "Lab CA")
        #expect(transport.lastRequest?.httpMethod == "PUT")
        #expect(transport.lastRequest?.nodeRelativePath == "/cas/2")
        #expect(transport.lastRequest?.jsonBody == .object(["name": .string("Lab CA")]))

        _ = try await node.certificates.authorities.importCA(.init(name: "X", p12: Data([1, 2])))
        #expect(transport.lastRequest?.nodeRelativePath == "/cas/import")
        #expect(transport.lastRequest?.jsonBody == .object(["name": .string("X"), "p12": .string("AQI=")]))

        let fileTransport = MockTransport(status: 200, body: Data([1, 2, 3]), headers: ["Content-Type": "application/x-x509-ca-cert"])
        let file = try await Node64.mock(fileTransport).certificates.authorities.file(2, format: .mobileconfig)
        #expect(file == Data([1, 2, 3]))
        #expect(fileTransport.lastRequest?.nodeRelativePath == "/cas/2/file?format=mobileconfig")
    }

    @Test("ACME authorities decode and create")
    func acmeAuthorities() async throws {
        let transport = MockTransport(status: 201, json: """
        {"id":1,"name":"ZeroSSL","directory":"https://acme.zerossl.com/v2/DV90","eab":true,"eab_kid":"kid",
         "custom_root":false,"certificates":0,"created_at":"2026-10-01T00:00:00Z"}
        """)

        let authority = try await Node64.mock(transport).certificates.acmeAuthorities.create(
            name: "ZeroSSL", directory: "https://acme.zerossl.com/v2/DV90", acceptTOS: true, eabKID: "kid", eabHMAC: "hmac"
        )

        #expect(authority.eabKID == "kid")
        #expect(authority.customRoot == false)
        #expect(transport.lastRequest?.jsonBody == .object([
            "name": .string("ZeroSSL"), "directory": .string("https://acme.zerossl.com/v2/DV90"),
            "accept_tos": .bool(true), "eab_kid": .string("kid"), "eab_hmac": .string("hmac"),
        ]))
    }

    @Test("Error documents become Node64Error.api")
    func error() async throws {
        let transport = MockTransport(status: 409, json: #"{"error":"Nutzungsbedingungen nicht angenommen","code":"tos_required"}"#)

        let error = await #expect(throws: Node64Error.self) {
            try await Node64.mock(transport).certificates.renew(7)
        }

        #expect(error?.code == "tos_required")
    }
}
