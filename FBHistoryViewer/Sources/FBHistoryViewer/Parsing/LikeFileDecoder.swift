import Foundation

// Raw Codable structs for decoding likes_and_reactions_*.json files.
// Two distinct formats exist in the export:
//   1. Numbered files (likes_and_reactions_1.json…): structured format with data[].reaction
//   2. Non-numbered file (likes_and_reactions.json): label_values format

// Format 1 — used by numbered files
struct RawLikeItem: Decodable {
    let timestamp: Int64
    let title: String?
    let data: [RawLikeData]?
}

struct RawLikeData: Decodable {
    let reaction: RawReactionData?
}

struct RawReactionData: Decodable {
    let reaction: String    // "LIKE", "LOVE", "HAHA", "WOW", "SAD", "ANGRY"
    let actor: String
}

// Format 2 — used by non-numbered likes_and_reactions.json
struct RawLikeLabelItem: Decodable {
    let timestamp: Int64
    let label_values: [RawLabelValue]?
    let fbid: String?
}

struct RawLabelValue: Decodable {
    let label: String?   // some entries are nested dicts with no label key
    let value: String?
    let href: String?
}
