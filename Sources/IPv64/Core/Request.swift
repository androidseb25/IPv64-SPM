import Foundation

/// A value that can be sent as a URL query parameter.
///
/// Internal on purpose, so `queryValue` does not leak into the public API of
/// `String`, `Int` and friends. Open enums are handled by an overload of
/// a generic `QueryItem` initializer.
protocol IPv64QueryValue: Sendable {
    var queryValue: String { get }
}

extension String: IPv64QueryValue {
    var queryValue: String { self }
}

extension Int: IPv64QueryValue {
    var queryValue: String { String(self) }
}

extension Double: IPv64QueryValue {
    var queryValue: String { String(self) }
}

extension Bool: IPv64QueryValue {
    var queryValue: String { self ? "true" : "false" }
}

extension Date: IPv64QueryValue {
    var queryValue: String { IPv64Coding.string(from: self) }
}

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// A URL path below the base URL. Interpolated values are percent-encoded as
/// a single path segment, so `"/domains/\(name)"` is safe for any `name`.
struct Path: Sendable, ExpressibleByStringInterpolation {
    struct StringInterpolation: StringInterpolationProtocol {
        var value = ""

        init(literalCapacity: Int, interpolationCount: Int) {
            value.reserveCapacity(literalCapacity)
        }

        mutating func appendLiteral(_ literal: String) {
            value += literal
        }

        mutating func appendInterpolation(_ segment: some CustomStringConvertible) {
            value += segment.description.addingPercentEncoding(withAllowedCharacters: Path.segmentAllowed) ?? ""
        }
    }

    private static let segmentAllowed: CharacterSet = {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/;?#%")
        return allowed
    }()

    let value: String

    init(stringLiteral value: String) {
        self.value = value
    }

    init(stringInterpolation: StringInterpolation) {
        self.value = stringInterpolation.value
    }
}

/// A single query parameter. `nil` values are dropped.
struct QueryItem: Sendable {
    let name: String
    let value: String?

    init(_ name: String, _ value: (any IPv64QueryValue)?) {
        self.name = name
        self.value = value?.queryValue
    }

    init<Value: IPv64OpenEnum>(_ name: String, _ value: Value?) {
        self.name = name
        self.value = value?.rawValue
    }
}

/// The body of a request.
enum RequestBody: Sendable {
    case json(any Encodable & Sendable)
    case multipart(MultipartFormData)
    case raw(Data, contentType: String)
}

/// Whether a request sends the API key.
enum Authorization: Sendable {
    /// The API key is required; the request fails with ``IPv64Error/missingAPIKey`` without one.
    case required
    /// The API key is sent if configured (public endpoints with extra data for accounts).
    case optional
    /// Never send the API key.
    case none
}

/// Description of an API call, turned into a `URLRequest` by ``IPv64``.
struct Request: Sendable {
    var method: HTTPMethod
    var path: Path
    var query: [QueryItem]
    var body: RequestBody?
    var authorization: Authorization
    var accept: String
    /// Additional request headers, e.g. `If-None-Match`.
    var headers: [String: String]

    init(
        _ method: HTTPMethod,
        _ path: Path,
        query: [QueryItem] = [],
        body: RequestBody? = nil,
        authorization: Authorization = .required,
        accept: String = "application/json",
        headers: [String: String] = [:]
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.body = body
        self.authorization = authorization
        self.accept = accept
        self.headers = headers
    }
}
