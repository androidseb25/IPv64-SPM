import Foundation

/// Errors thrown by ``IPv64``.
public enum IPv64Error: Error, Sendable {
    /// The server answered with an RFC 9457 problem document.
    case api(IPv64Problem)
    /// The server answered with an error status but no readable problem document.
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

    /// The HTTP status code, if the error came from the server.
    public var statusCode: Int? {
        switch self {
        case .api(let problem): problem.status
        case .httpStatus(let code, _): code
        default: nil
        }
    }

    /// The machine-readable error code such as `domain_not_found`, if available.
    public var code: String? {
        if case .api(let problem) = self { problem.code } else { nil }
    }
}

extension IPv64Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .api(let problem): problem.detail
        case .httpStatus(let code, _): "HTTP status \(code)"
        case .missingAPIKey: "This endpoint requires an API key."
        case .invalidResponse: "The server response was not an HTTP response."
        case .invalidRequest(let reason): "Invalid request: \(reason)"
        case .decoding(let error, _): "The response could not be decoded: \(error)"
        case .encoding(let error): "The request body could not be encoded: \(error)"
        }
    }
}

/// An error returned by the API as `application/problem+json` (RFC 9457).
public struct IPv64Problem: Codable, Hashable, Sendable {
    /// Link to the error description, e.g. `https://ipv64.net/api/v2/errors#domain_not_found`.
    public var type: String
    /// HTTP status text.
    public var title: String
    /// HTTP status code.
    public var status: Int
    /// Human-readable error message.
    public var detail: String
    /// Machine-readable error code, e.g. `domain_not_found`.
    public var code: String
    /// Affected input field, if any.
    public var field: String?
    /// Seconds until the next attempt (on 429 and some 409).
    public var retryAfter: Int?

    public init(
        type: String,
        title: String,
        status: Int,
        detail: String,
        code: String,
        field: String? = nil,
        retryAfter: Int? = nil
    ) {
        self.type = type
        self.title = title
        self.status = status
        self.detail = detail
        self.code = code
        self.field = field
        self.retryAfter = retryAfter
    }

    enum CodingKeys: String, CodingKey {
        case type, title, status, detail, code, field
        case retryAfter = "retry_after"
    }
}
