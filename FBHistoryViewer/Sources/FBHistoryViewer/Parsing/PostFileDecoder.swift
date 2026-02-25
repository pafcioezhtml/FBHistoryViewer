import Foundation

// Raw Codable structs for decoding timeline post JSON files.

struct RawPost: Decodable {
    let timestamp: Int64
    let title: String?
    let data: [RawPostDataItem]?
    let attachments: [RawPostAttachment]?
    let tags: [RawTag]?
}

struct RawPostDataItem: Decodable {
    let post: String?
    let update_timestamp: Int64?

    // Ignore unknown keys gracefully
    private enum CodingKeys: String, CodingKey {
        case post
        case update_timestamp
    }
}

struct RawPostAttachment: Decodable {
    let data: [RawAttachmentData]?
}

struct RawAttachmentData: Decodable {
    let external_context: RawExternalContext?
    let media: RawPostMedia?
    let text: String?
}

struct RawExternalContext: Decodable {
    let url: String?
    let source: String?
    let name: String?
}

struct RawPostMedia: Decodable {
    let uri: String?
    let creation_timestamp: Int64?
    let description: String?
    let title: String?
}

struct RawTag: Decodable {
    let name: String?
}
