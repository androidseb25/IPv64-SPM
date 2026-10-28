import Foundation

extension IPv64.HC2 {
    /// Endpoints for notification channels.
    public struct Channels: Sendable {
        let client: IPv64

        /// Channel types with their configuration fields.
        ///
        /// `GET /hc2/channel-types`
        public func types() async throws -> [HC2ChannelType] {
            try await client.send(Request(.get, "/hc2/channel-types"))
        }

        /// Lists channels.
        ///
        /// `GET /hc2/channels`
        public func list() async throws -> [HC2Channel] {
            try await client.send(Request(.get, "/hc2/channels"))
        }

        /// Creates a channel.
        ///
        /// Mail and SMS channels must be confirmed by code in the portal afterwards
        /// (`verification_required`); nothing is sent before that.
        ///
        /// `POST /hc2/channels`
        public func create(_ channel: HC2ChannelInput) async throws -> HC2Channel {
            try await client.send(Request(.post, "/hc2/channels", body: .json(channel)))
        }

        /// A channel.
        ///
        /// `GET /hc2/channels/{id}`
        public func get(_ id: Int) async throws -> HC2Channel {
            try await client.send(Request(.get, "/hc2/channels/\(id)"))
        }

        /// Updates a channel. Omit secret config fields to keep them unchanged.
        ///
        /// `PATCH /hc2/channels/{id}`
        public func update(_ id: Int, _ channel: HC2ChannelInput) async throws -> HC2Channel {
            try await client.send(Request(.patch, "/hc2/channels/\(id)", body: .json(channel)))
        }

        /// Deletes a channel.
        ///
        /// `DELETE /hc2/channels/{id}`
        public func delete(_ id: Int) async throws {
            try await client.sendWithoutContent(Request(.delete, "/hc2/channels/\(id)"))
        }

        /// Sends a test message through a channel.
        ///
        /// `POST /hc2/channels/{id}/test`
        public func sendTest(_ id: Int) async throws -> HC2ChannelTestResult {
            try await client.send(Request(.post, "/hc2/channels/\(id)/test"))
        }

        /// Sends a message through a verified, active ipv64 channel (`ipv64_mail`, `ipv64_sms`, `app`) directly,
        /// without the hub, e.g. for messages of node modules (DynDNS).
        ///
        /// The recipient comes only from the channel. Mails are set in the ipv64 design; SMS count against the
        /// daily limit of the plan. Rate limit: 30 at once, then 30 per hour, at most 200 per day. An `eventID`
        /// that was already sent successfully within 24 hours is not sent again (`duplicate == true`).
        ///
        /// - Parameters:
        ///   - id: Channel ID.
        ///   - subject: Subject, at most 200 characters.
        ///   - text: Text, at most 4000 characters; lines of the form `Label: Value` appear as a table in the mail.
        ///   - kind: Kind of message, e.g. `dyndns_ip`, `dyndns_fail` (controls colour and status of the mail), at most 40 characters.
        ///   - eventID: Identifier for detecting duplicates (24 h), at most 100 characters.
        ///   - source: Source, e.g. `node64`, at most 60 characters.
        ///
        /// `POST /hc2/channels/{id}/send`
        public func send(
            _ id: Int,
            subject: String,
            text: String,
            kind: String? = nil,
            eventID: String? = nil,
            source: String? = nil
        ) async throws -> HC2ChannelSendResult {
            struct Body: Encodable, Sendable {
                let subject: String
                let text: String
                let kind: String?
                let eventID: String?
                let source: String?

                enum CodingKeys: String, CodingKey {
                    case subject, text, kind
                    case eventID = "event_id"
                    case source
                }
            }
            let body = Body(subject: subject, text: text, kind: kind, eventID: eventID, source: source)
            return try await client.send(Request(.post, "/hc2/channels/\(id)/send", body: .json(body)))
        }
    }
}

/// Result of ``IPv64/HC2/Channels/sendTest(_:)``.
public struct HC2ChannelTestResult: Codable, Hashable, Sendable {
    /// The message was sent.
    public let sent: Bool?
    /// Node channel: the node sends the message itself.
    public let queuedAtNode: Bool?

    enum CodingKeys: String, CodingKey {
        case sent
        case queuedAtNode = "queued_at_node"
    }
}

/// Result of ``IPv64/HC2/Channels/send(_:subject:text:kind:eventID:source:)``.
public struct HC2ChannelSendResult: Codable, Hashable, Sendable {
    /// The message was sent.
    public let sent: Bool?
    /// The `event_id` was already sent within 24 hours, nothing was sent.
    public let duplicate: Bool?
    /// SMS left today (SMS channels only); `nil` means unlimited.
    public let smsLeft: Int?

    enum CodingKeys: String, CodingKey {
        case sent, duplicate
        case smsLeft = "sms_left"
    }
}
