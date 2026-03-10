import Foundation
import GRDB

actor GroupPostImporter {
    private let dbQueue: DatabaseQueue
    private let decoder = JSONDecoder()

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func importAll(groupsDirectory: URL) async throws -> Int {
        let fileURL = groupsDirectory.appendingPathComponent("group_posts_and_comments.json")
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return 0 }

        let data = try Data(contentsOf: fileURL)
        let file = try decoder.decode(RawGroupPostFile.self, from: data)

        // Pre-build records outside the @Sendable write closure to avoid actor isolation issues
        var records: [PostRecord] = []
        records.reserveCapacity(file.group_posts_v2.count)

        for raw in file.group_posts_v2 {
            let content = raw.data?
                .compactMap { $0.post }
                .filter { !$0.isEmpty }
                .map { $0.fixedFacebookEncoding }
                .first

            let externalURL = raw.attachments?
                .compactMap { $0.data }
                .flatMap { $0 }
                .compactMap { $0.external_context?.url }
                .first

            let hasMedia = raw.attachments?
                .compactMap { $0.data }
                .flatMap { $0 }
                .contains { $0.media != nil } ?? false

            let fixedTitle = raw.title?.fixedFacebookEncoding
            let groupName = groupPostExtractGroupName(from: fixedTitle)

            records.append(PostRecord(
                id: nil,
                source: PostSource.group.rawValue,
                timestamp: raw.timestamp,
                title: fixedTitle,
                content: content,
                external_url: externalURL,
                group_name: groupName,
                has_media: hasMedia
            ))
        }

        let insertRecords = records
        try await dbQueue.write { db in
            for var record in insertRecords {
                try record.insert(db)
            }
        }

        return insertRecords.count
    }
}

private func groupPostExtractGroupName(from title: String?) -> String? {
    guard let title = title else { return nil }
    if let range = title.range(of: " posted in ") {
        let after = String(title[range.upperBound...])
        return after.hasSuffix(".") ? String(after.dropLast()) : after
    }
    return nil
}
