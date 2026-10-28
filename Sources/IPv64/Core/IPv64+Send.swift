import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension IPv64 {
    /// Sends `request` and decodes the `data` member of the response envelope.
    func send<Value: Decodable>(_ request: Request, as type: Value.Type = Value.self) async throws -> Value {
        let (data, _) = try await perform(request)
        return try decode(DataEnvelope<Value>.self, from: data).data
    }

    /// Sends `request` and decodes a cursor-paginated `{"data": [...], "meta": {...}}` response.
    func sendPage<Item, Meta>(
        _ request: Request,
        of item: Item.Type = Item.self,
        meta: Meta.Type = Meta.self
    ) async throws -> IPv64Page<Item, Meta> {
        let (data, _) = try await perform(request)
        return try decode(IPv64Page<Item, Meta>.self, from: data)
    }

    /// Sends `request` and ignores the response body (e.g. `204 No Content`).
    func sendWithoutContent(_ request: Request) async throws {
        _ = try await perform(request)
    }

    /// Sends `request` and returns the body as UTF-8 text (`text/plain` responses).
    func sendText(_ request: Request) async throws -> String {
        var request = request
        request.accept = "text/plain"
        let (data, _) = try await perform(request)
        guard let text = String(data: data, encoding: .utf8) else {
            throw IPv64Error.decoding(
                DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Body is not UTF-8 text.")),
                body: data
            )
        }
        return text
    }

    /// Sends `request` and decodes the whole body without an envelope.
    func sendUnwrapped<Value: Decodable>(_ request: Request, as type: Value.Type = Value.self) async throws -> Value {
        let (data, _) = try await perform(request)
        return try decode(Value.self, from: data)
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

    func makeURLRequest(for request: Request) throws(IPv64Error) -> URLRequest {
        do {
            return try request.urlRequest(in: requestContext)
        } catch {
            switch error {
            case .missingAPIKey: throw .missingAPIKey
            case .invalidRequest(let reason): throw .invalidRequest(reason)
            case .encoding(let underlying): throw .encoding(underlying)
            }
        }
    }

    private var requestContext: RequestContext {
        var authorizedHeaders: [String: String] = [:]
        if let actAs = configuration.actAs {
            authorizedHeaders["X-IPv64-Act-As"] = actAs
        }
        let credential = configuration.apiKey.map { apiKey in
            switch configuration.authentication {
            case .bearer: RequestContext.Credential(header: "Authorization", value: "Bearer \(apiKey)")
            case .apiKeyHeader: RequestContext.Credential(header: "X-API-Key", value: apiKey)
            }
        }
        return RequestContext(
            baseURL: configuration.baseURL,
            credential: credential,
            authorizedHeaders: authorizedHeaders,
            userAgent: configuration.userAgent,
            timeoutInterval: configuration.timeoutInterval,
            additionalAccept: "application/problem+json"
        )
    }

    /// Decodes the `data` member of a response envelope.
    func decodeEnvelope<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        try decode(DataEnvelope<Value>.self, from: data).data
    }

    private func decode<Value: Decodable>(_ type: Value.Type, from data: Data) throws -> Value {
        do {
            return try IPv64Coding.makeDecoder().decode(Value.self, from: data)
        } catch {
            throw IPv64Error.decoding(error, body: data)
        }
    }

    private func error(for response: HTTPURLResponse, body: Data) -> IPv64Error {
        guard var problem = try? IPv64Coding.makeDecoder().decode(IPv64Problem.self, from: body) else {
            return .httpStatus(code: response.statusCode, body: body)
        }
        if problem.retryAfter == nil,
           let header = response.value(forHTTPHeaderField: "Retry-After"),
           let seconds = Int(header) {
            problem.retryAfter = seconds
        }
        return .api(problem)
    }
}
