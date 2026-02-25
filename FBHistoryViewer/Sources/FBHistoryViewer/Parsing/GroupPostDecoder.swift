import Foundation

// Raw Codable structs for decoding group_posts_and_comments.json

struct RawGroupPostFile: Decodable {
    let group_posts_v2: [RawGroupPost]
}

struct RawGroupPost: Decodable {
    let timestamp: Int64
    let title: String?
    let data: [RawGroupPostDataItem]?
    let attachments: [RawGroupPostAttachment]?
}

struct RawGroupPostDataItem: Decodable {
    let post: String?
    let update_timestamp: Int64?

    private enum CodingKeys: String, CodingKey {
        case post
        case update_timestamp
    }
}

struct RawGroupPostAttachment: Decodable {
    let data: [RawGroupAttachmentData]?
}

struct RawGroupAttachmentData: Decodable {
    let external_context: RawExternalContext?
    let media: RawPostMedia?
}
