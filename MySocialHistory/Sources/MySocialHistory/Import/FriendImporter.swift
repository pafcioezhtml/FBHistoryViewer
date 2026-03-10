import Foundation
import GRDB

actor FriendImporter {
    private let dbQueue: DatabaseQueue
    private let decoder = JSONDecoder()

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Imports friends from `connections/friends/` which sits alongside `your_facebook_activity/`.
    /// Returns total number of friend records imported.
    func importAll(exportParent: URL) async throws -> Int {
        let friendsDir = exportParent
            .appendingPathComponent("connections")
            .appendingPathComponent("friends")

        guard FileManager.default.fileExists(atPath: friendsDir.path) else { return 0 }

        var records: [FriendRecord] = []

        // Current friends
        let currentURL = friendsDir.appendingPathComponent("your_friends.json")
        if let data = try? Data(contentsOf: currentURL),
           let file = try? decoder.decode(RawFriendsFile.self, from: data) {
            for entry in file.friends_v2 ?? [] {
                guard let name = entry.name else { continue }
                records.append(FriendRecord(
                    id: nil,
                    name: name.fixedFacebookEncoding,
                    timestamp: Int64(entry.timestamp),
                    status: "current"
                ))
            }
        }

        // Removed friends
        let removedURL = friendsDir.appendingPathComponent("removed_friends.json")
        if let data = try? Data(contentsOf: removedURL),
           let file = try? decoder.decode(RawDeletedFriendsFile.self, from: data) {
            for entry in file.deleted_friends_v2 ?? [] {
                guard let name = entry.name else { continue }
                records.append(FriendRecord(
                    id: nil,
                    name: name.fixedFacebookEncoding,
                    timestamp: Int64(entry.timestamp),
                    status: "removed"
                ))
            }
        }

        // Rejected friend requests (people you declined)
        let rejectedURL = friendsDir.appendingPathComponent("rejected_friend_requests.json")
        if let data = try? Data(contentsOf: rejectedURL),
           let file = try? decoder.decode(RawRejectedRequestsFile.self, from: data) {
            for entry in file.rejected_requests_v2 ?? [] {
                guard let name = entry.name else { continue }
                records.append(FriendRecord(
                    id: nil,
                    name: name.fixedFacebookEncoding,
                    timestamp: Int64(entry.timestamp),
                    status: "rejected"
                ))
            }
        }

        guard !records.isEmpty else { return 0 }

        let insertRecords = records
        try await dbQueue.write { db in
            for var r in insertRecords { try r.insert(db) }
        }
        return records.count
    }
}

// MARK: - Raw JSON

private struct RawFriendsFile: Decodable {
    let friends_v2: [RawFriendEntry]?
}

private struct RawDeletedFriendsFile: Decodable {
    let deleted_friends_v2: [RawFriendEntry]?
}

private struct RawRejectedRequestsFile: Decodable {
    let rejected_requests_v2: [RawFriendEntry]?
}

private struct RawFriendEntry: Decodable {
    let name: String?
    let timestamp: Int
}
