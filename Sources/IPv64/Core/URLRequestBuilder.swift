import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Client-wide settings applied to every ``Request`` when it becomes a `URLRequest`.
///
/// Shared by ``IPv64`` and ``Node64`` so path/query encoding, authentication and
/// body handling behave identically for both APIs.
struct RequestContext: Sendable {
    struct Credential: Sendable {
        let header: String
        let value: String
    }

    var baseURL: URL
    /// Header carrying the API key; `nil` when the client has no key.
    var credential: Credential?
    /// Headers sent only on requests that may carry credentials (not on `.none`).
    var authorizedHeaders: [String: String]
    var userAgent: String
    var timeoutInterval: TimeInterval
    /// Appended to every `Accept` header, e.g. `application/problem+json`.
    var additionalAccept: String?
}

/// Why a ``Request`` could not be turned into a `URLRequest`.
enum RequestBuildError: Error {
    case missingAPIKey
    case invalidRequest(String)
    case encoding(any Error)
}

extension Request {
    func urlRequest(in context: RequestContext) throws(RequestBuildError) -> URLRequest {
        let base = context.baseURL.absoluteString.trimmingSuffix("/")
        guard var components = URLComponents(string: base + path.value) else {
            throw .invalidRequest("Invalid path \(path.value)")
        }
        let queryItems = query.compactMap { item in
            item.value.map { URLQueryItem(name: item.name, value: $0) }
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
            // `+` is decoded as a space by many servers; encode it explicitly.
            components.percentEncodedQuery = components.percentEncodedQuery?
                .replacingOccurrences(of: "+", with: "%2B")
        }
        guard let url = components.url else {
            throw .invalidRequest("Invalid URL for path \(path.value)")
        }

        var urlRequest = URLRequest(url: url, timeoutInterval: context.timeoutInterval)
        urlRequest.httpMethod = method.rawValue
        let acceptValue = context.additionalAccept.map { "\(accept), \($0)" } ?? accept
        urlRequest.setValue(acceptValue, forHTTPHeaderField: "Accept")
        urlRequest.setValue(context.userAgent, forHTTPHeaderField: "User-Agent")
        for (name, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: name)
        }

        switch (authorization, context.credential) {
        case (.required, nil):
            throw .missingAPIKey
        case (.required, let credential?), (.optional, let credential?):
            urlRequest.setValue(credential.value, forHTTPHeaderField: credential.header)
        case (.optional, nil), (.none, _):
            break
        }

        if authorization != .none {
            for (name, value) in context.authorizedHeaders {
                urlRequest.setValue(value, forHTTPHeaderField: name)
            }
        }

        switch body {
        case nil:
            break
        case .json(let body):
            do {
                urlRequest.httpBody = try IPv64Coding.makeEncoder().encode(body)
            } catch {
                throw .encoding(error)
            }
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        case .multipart(let form):
            urlRequest.httpBody = form.encoded()
            urlRequest.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
        case .raw(let data, let contentType):
            urlRequest.httpBody = data
            urlRequest.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        return urlRequest
    }
}

private extension String {
    func trimmingSuffix(_ suffix: String) -> String {
        hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
    }
}
