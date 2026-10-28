import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Performs HTTP requests for an ``IPv64`` client.
///
/// Implement this protocol to plug in a custom networking stack or to stub
/// responses in tests. Implementations should honor task cancellation, as the
/// `URLSession` async APIs used by ``URLSessionTransport`` do.
public protocol IPv64Transport: Sendable {
    /// Sends `request` and returns the response body and HTTP response.
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// The default transport, backed by `URLSession`.
public struct URLSessionTransport: IPv64Transport {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw IPv64Error.invalidResponse
        }
        return (data, httpResponse)
    }
}
