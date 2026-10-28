import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension Node64 {
    /// Sends `request` and decodes the whole body (the node uses no envelope).
    func send<Value: Decodable>(_ request: Request, as type: Value.Type = Value.self) async throws -> Value {
        let (data, _) = try await perform(request)
        return try decode(Value.self, from: data)
    }

    /// Sends `request` and ignores the response body.
    func sendWithoutContent(_ request: Request) async throws {
        _ = try await perform(request)
    }

    /// Sends `request` and returns the body as arbitrary JSON; an empty body becomes `.null`.
    ///
    /// For endpoints whose response the spec describes only in prose.
    func sendJSON(_ request: Request) async throws -> JSONValue {
        let (data, _) = try await perform(request)
        if data.isEmpty { return .null }
        return try decode(JSONValue.self, from: data)
    }

    /// Sends `request` and returns the body as UTF-8 text.
    func sendText(_ request: Request, accept: String = "text/plain") async throws -> String {
        var request = request
        request.accept = accept
        let (data, _) = try await perform(request)
        guard let text = String(data: data, encoding: .utf8) else {
            throw Node64Error.decoding(
                DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Body is not UTF-8 text.")),
                body: data
            )
        }
        return text
    }

    /// Sends `request` and returns the raw body (files such as backups or certificates).
    func sendData(_ request: Request, accept: String) async throws -> Data {
        var request = request
        request.accept = accept
        return try await perform(request).0
    }

    /// Sends `request` and returns the raw body and response, after error handling.
    ///
    /// `304 Not Modified` counts as success only for conditional requests (`If-None-Match`).
    func perform(_ request: Request) async throws -> (Data, HTTPURLResponse) {
        let urlRequest = try makeURLRequest(for: request)
        let (data, response) = try await transport.send(urlRequest)
        let isNotModified = response.statusCode == 304 && request.headers["If-None-Match"] != nil
        guard (200..<300).contains(response.statusCode) || isNotModified else {
            throw error(for: response, body: data)
        }
        return (data, response)
    }

    func makeURLRequest(for request: Request) throws(Node64Error) -> URLRequest {
        var authorizedHeaders: [String: String] = [:]
        if let agentActor = configuration.agentActor {
            authorizedHeaders["X-Agent-Actor"] = agentActor
        }
        let context = RequestContext(
            baseURL: configuration.baseURL,
            credential: configuration.apiKey.map { .init(header: "Authorization", value: "Bearer \($0)") },
            authorizedHeaders: authorizedHeaders,
            userAgent: configuration.userAgent,
            timeoutInterval: configuration.timeoutInterval,
            additionalAccept: nil
        )
        do {
            return try request.urlRequest(in: context)
        } catch {
            switch error {
            case .missingAPIKey: throw .missingAPIKey
            case .invalidRequest(let reason): throw .invalidRequest(reason)
            case .encoding(let underlying): throw .encoding(underlying)
            }
        }
    }

    func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        do {
            return try IPv64Coding.makeDecoder().decode(Value.self, from: data)
        } catch {
            throw Node64Error.decoding(error, body: data)
        }
    }

    private func error(for response: HTTPURLResponse, body: Data) -> Node64Error {
        let retryAfter = response.value(forHTTPHeaderField: "Retry-After").flatMap { Int($0) }
        guard let document = try? JSONDecoder().decode(Node64APIError.Body.self, from: body),
              document.error != nil || document.code != nil || document.text != nil else {
            if response.statusCode == 429 {
                return .api(Node64APIError(status: 429, retryAfter: retryAfter))
            }
            return .httpStatus(code: response.statusCode, body: body)
        }
        return .api(Node64APIError(
            status: response.statusCode,
            error: document.error,
            field: document.field,
            fields: document.fields,
            code: document.code,
            key: document.key,
            text: document.text,
            retryAfter: retryAfter
        ))
    }
}
