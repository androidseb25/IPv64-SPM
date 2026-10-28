import Foundation

/// A page of a cursor-paginated list (`{"data": [...], "meta": {...}}`).
///
/// Pass the cursor from ``meta`` (for example `nextBefore`) to the next call
/// to fetch older entries.
public struct IPv64Page<Item: Decodable & Sendable, Meta: Decodable & Sendable>: Decodable, Sendable {
    /// The entries of this page.
    public let items: [Item]
    /// Pagination metadata. `nil` if the server sent none.
    public let meta: Meta?

    enum CodingKeys: String, CodingKey {
        case items = "data"
        case meta
    }
}

extension IPv64Page: Equatable where Item: Equatable, Meta: Equatable {}
extension IPv64Page: Hashable where Item: Hashable, Meta: Hashable {}

/// The `{"data": ...}` envelope every JSON response is wrapped in.
struct DataEnvelope<Value: Decodable>: Decodable {
    let data: Value
}
