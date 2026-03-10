import Foundation
import GRDB

actor CommentImporter {
    private let dbQueue: DatabaseQueue
    private let decoder = JSONDecoder()

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func importAll(reactionsDirectory: URL) async throws -> Int {
        let fileURL = reactionsDirectory.appendingPathComponent("comments.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return 0 }

        let data = try Data(contentsOf: fileURL)
        let file = try decoder.decode(RawCommentFile.self, from: data)

        var records: [CommentRecord] = []
        for raw in file.comments_v2 {
            let text = raw.data?
                .compactMap { $0.comment?.comment }
                .filter { !$0.isEmpty }
                .map { $0.fixedFacebookEncoding }
                .first
            records.append(CommentRecord(
                id: nil,
                timestamp: raw.timestamp,
                title: fixOptional(raw.title),
                comment_text: text
            ))
        }

        let insertRecords = records
        try await dbQueue.write { db in
            for var r in insertRecords { try r.insert(db) }
        }
        return insertRecords.count
    }
}
