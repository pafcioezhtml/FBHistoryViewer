import Foundation

// Raw Codable structs for decoding comments.json

struct RawCommentFile: Decodable {
    let comments_v2: [RawComment]
}

struct RawComment: Decodable {
    let timestamp: Int64
    let title: String?
    let data: [RawCommentData]?
}

struct RawCommentData: Decodable {
    let comment: RawCommentContent?
}

struct RawCommentContent: Decodable {
    let timestamp: Int64?
    let comment: String?
    let author: String?
}
