import Foundation

/// A `multipart/form-data` request body.
struct MultipartFormData: Sendable {
    struct Part: Sendable {
        var name: String
        var filename: String?
        var contentType: String?
        var data: Data
    }

    let boundary: String
    private(set) var parts: [Part] = []

    init(boundary: String = "IPv64Boundary-\(UUID().uuidString)") {
        self.boundary = boundary
    }

    var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    mutating func append(_ value: String, name: String) {
        parts.append(Part(name: name, data: Data(value.utf8)))
    }

    mutating func append(_ data: Data, name: String, filename: String, contentType: String) {
        parts.append(Part(name: name, filename: filename, contentType: contentType, data: data))
    }

    func encoded() -> Data {
        var body = Data()
        for part in parts {
            body.append("--\(boundary)\r\n")
            var disposition = "Content-Disposition: form-data; name=\"\(escaped(part.name))\""
            if let filename = part.filename {
                disposition += "; filename=\"\(escaped(filename))\""
            }
            body.append(disposition + "\r\n")
            if let contentType = part.contentType {
                body.append("Content-Type: \(contentType)\r\n")
            }
            body.append("\r\n")
            body.append(part.data)
            body.append("\r\n")
        }
        body.append("--\(boundary)--\r\n")
        return body
    }

    private func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\"", with: "%22")
    }
}

private extension Data {
    mutating func append(_ string: String) {
        append(Data(string.utf8))
    }
}
