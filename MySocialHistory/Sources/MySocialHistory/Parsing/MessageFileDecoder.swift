import Foundation

// Raw Codable structs for decoding message JSON files.
// Encoding fix is NOT applied here — it's applied in MessageImporter.

struct RawMessageFile: Decodable {
    let participants: [RawParticipant]
    let messages: [RawMessage]
    let title: String
    let thread_path: String
    let is_still_participant: Bool?
}

struct RawParticipant: Decodable {
    let name: String
}

struct RawMessage: Decodable {
    let sender_name: String
    let timestamp_ms: Int64
    let content: String?
    let photos: [RawMedia]?
    let videos: [RawMedia]?
    let audio_files: [RawMedia]?
    let gifs: [RawMedia]?
    let files: [RawMedia]?
    let share: RawShare?
    let reactions: [RawReaction]?
    let is_geoblocked_for_viewer: Bool?
    let is_unsent_image_by_messenger_kid_parent: Bool?
}

struct RawMedia: Decodable {
    let uri: String?
    let creation_timestamp: Int64?
}

struct RawShare: Decodable {
    let link: String?
    let share_text: String?
}

struct RawReaction: Decodable {
    let reaction: String
    let actor: String
}
