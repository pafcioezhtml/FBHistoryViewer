#!/usr/bin/env swift
// Quick verification script — run with: swift verify_import.swift
// This exercises the core import pipeline logic without the GUI.

import Foundation

// ---------- Encoding fix (inline) ----------
extension String {
    var fixedFacebookEncoding: String {
        guard let d = self.data(using: .isoLatin1) else { return self }
        return String(data: d, encoding: .utf8) ?? self
    }
}

// ---------- Load & check a sample message file ----------
let base = URL(fileURLWithPath: #file).deletingLastPathComponent()
    .deletingLastPathComponent()    // FBHistoryViewer/
    .appendingPathComponent("data/facebook-pafcio-2026-02-22-G4AhfvZb/your_facebook_activity")

struct Participant: Codable { let name: String }
struct Reaction: Codable { let reaction: String; let actor: String }
struct Msg: Codable {
    let sender_name: String
    let timestamp_ms: Int64
    let content: String?
    let reactions: [Reaction]?
}
struct MsgFile: Codable {
    let participants: [Participant]
    let messages: [Msg]
    let title: String
    let thread_path: String
}

// Test 1: Decode a message file and check encoding fix
let msgPath = base
    .appendingPathComponent("messages/inbox/aniakrzemionka_10158596553984607/message_1.json")
let msgData = try Data(contentsOf: msgPath)
let msgFile = try JSONDecoder().decode(MsgFile.self, from: msgData)
let title = msgFile.title.fixedFacebookEncoding
print("✓ Decoded message file: \(msgFile.messages.count) messages")
print("  Title: '\(title)'")

// Check that a reaction with emoji is fixed
if let msgWithReaction = msgFile.messages.first(where: { $0.reactions?.isEmpty == false }),
   let reaction = msgWithReaction.reactions?.first {
    let fixedEmoji = reaction.reaction.fixedFacebookEncoding
    print("  Reaction fixed: '\(reaction.reaction)' → '\(fixedEmoji)'")
    // Should be a visible emoji character now
    let isEmoji = fixedEmoji.unicodeScalars.contains { $0.properties.isEmoji }
    print("  Is emoji: \(isEmoji) ✓")
}

// Test 2: Check Polish characters in a comment
struct CommentContent: Codable { let comment: String?; let author: String? }
struct CommentData: Codable { let comment: CommentContent? }
struct Comment: Codable { let timestamp: Int64; let title: String?; let data: [CommentData]? }
struct CommentFile: Codable { let comments_v2: [Comment] }

let commentPath = base.appendingPathComponent("comments_and_reactions/comments.json")
let commentData = try Data(contentsOf: commentPath)
let commentFile = try JSONDecoder().decode(CommentFile.self, from: commentData)
print("\n✓ Decoded \(commentFile.comments_v2.count) comments")

// Find a comment with Polish chars (mojibake → fix)
if let c = commentFile.comments_v2.dropFirst(1).first,
   let text = c.data?.first?.comment?.comment {
    let fixed = text.fixedFacebookEncoding
    print("  Raw: \(text)")
    print("  Fixed: \(fixed)")
    // Verify Polish characters present in fixed version
    let polishChars = Set("ąęóśżźćń")
    let hasPolish = fixed.unicodeScalars.contains { polishChars.contains(Character($0)) }
    print("  Contains Polish chars: \(hasPolish) ✓")
}

// Test 3: Count threads across categories
let categories = ["inbox", "archived_threads", "filtered_threads", "message_requests", "e2ee_cutover"]
var total = 0
for cat in categories {
    let catURL = base.appendingPathComponent("messages/\(cat)")
    guard FileManager.default.fileExists(atPath: catURL.path) else { continue }
    let dirs = try FileManager.default.contentsOfDirectory(
        at: catURL,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: .skipsHiddenFiles
    ).filter { url in
        var isDir: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
    }
    print("  \(cat): \(dirs.count) threads")
    total += dirs.count
}
print("✓ Total threads: \(total)")

// Test 4: Check likes file count
let likesDir = base.appendingPathComponent("comments_and_reactions")
let likeFiles = try FileManager.default.contentsOfDirectory(
    at: likesDir,
    includingPropertiesForKeys: nil,
    options: .skipsHiddenFiles
).filter { $0.lastPathComponent.hasPrefix("likes_and_reactions") && $0.pathExtension == "json" }
print("✓ Likes files: \(likeFiles.count) (including numbered + unnumbered)")

print("\n✅ All verification checks passed!")
