import Foundation

/// Errors thrown by ``Node64``.
public enum Node64Error: Error, Sendable {
    /// The node answered with an error document (`{"error": "…"}`).
    case api(Node64APIError)
    /// The node answered with an error status but no readable error document.
    case httpStatus(code: Int, body: Data)
    /// The endpoint requires an API key, but the client has none.
    case missingAPIKey
    /// The response was not an HTTP response.
    case invalidResponse
    /// The request URL could not be built from the given parameters.
    case invalidRequest(String)
    /// The response body could not be decoded.
    case decoding(any Error, body: Data)
    /// A request body could not be encoded.
    case encoding(any Error)

    /// The HTTP status code, if the error came from the node.
    public var statusCode: Int? {
        switch self {
        case .api(let error): error.status
        case .httpStatus(let code, _): code
        default: nil
        }
    }

    /// The machine-readable code (e.g. `no_api_key`) or i18n key, if the node sent one.
    public var code: String? {
        if case .api(let error) = self { error.code ?? error.key } else { nil }
    }
}

extension Node64Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .api(let error): error.text ?? error.error ?? "HTTP status \(error.status)"
        case .httpStatus(let code, _): "HTTP status \(code)"
        case .missingAPIKey: "This endpoint requires an API key."
        case .invalidResponse: "The server response was not an HTTP response."
        case .invalidRequest(let reason): "Invalid request: \(reason)"
        case .decoding(let error, _): "The response could not be decoded: \(error)"
        case .encoding(let error): "The request body could not be encoded: \(error)"
        }
    }
}

/// An error document returned by a Node64 node.
///
/// The node uses a few variants of `{"error": "…"}`; all their fields are optional here.
public struct Node64APIError: Codable, Hashable, Sendable {
    /// HTTP status code of the response (not part of the JSON body).
    public var status: Int
    /// Error message, e.g. `invalid api key`.
    public var error: String?
    /// Affected input field, if any.
    public var field: String?
    /// Messages per input field (validation errors).
    public var fields: [String: String]?
    /// Machine-readable code, e.g. `no_api_key`, `limit_reached` (PROXY64 online errors).
    public var code: String?
    /// i18n key of the message, e.g. `hc.status.err.slug` (status page errors).
    public var key: String?
    /// Localized error text with a hint how to fix it.
    public var text: String?
    /// Seconds to wait before retrying, from the `Retry-After` header (429).
    public var retryAfter: Int?

    public init(
        status: Int,
        error: String? = nil,
        field: String? = nil,
        fields: [String: String]? = nil,
        code: String? = nil,
        key: String? = nil,
        text: String? = nil,
        retryAfter: Int? = nil
    ) {
        self.status = status
        self.error = error
        self.field = field
        self.fields = fields
        self.code = code
        self.key = key
        self.text = text
        self.retryAfter = retryAfter
    }

    /// The JSON body without the HTTP-level fields.
    struct Body: Decodable {
        let error: String?
        let field: String?
        let fields: [String: String]?
        let code: String?
        let key: String?
        let text: String?
    }
}
