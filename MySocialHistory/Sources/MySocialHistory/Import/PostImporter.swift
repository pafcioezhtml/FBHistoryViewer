import Foundation
import GRDB

actor PostImporter {
    private let dbQueue: DatabaseQueue
    private let decoder = JSONDecoder()

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func importAll(postsDirectory: URL) async throws -> Int {
        guard FileManager.default.fileExists(atPath: postsDirectory.path) else { return 0 }

        let allFiles = (try? FileManager.default.contentsOfDirectory(
            at: postsDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []

        let postFiles = allFiles
            .filter { $0.lastPathComponent.hasPrefix("your_posts__") && $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        var total = 0
        for fileURL in postFiles {
            total += try await importFile(fileURL, source: PostSource.timeline.rawValue)
        }
        return total
    }

    private func importFile(_ fileURL: URL, source: String) async throws -> Int {
        let data = try Data(contentsOf: fileURL)
        let rawPosts = try decoder.decode([RawPost].self, from: data)

        // Pre-build records to avoid mutable captures in @Sendable closure
        struct PostWithTags {
            var record: PostRecord
            let tags: [String]
        }
        var items: [PostWithTags] = []
        items.reserveCapacity(rawPosts.count)
        for raw in rawPosts {
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

            let tagNames = (raw.tags ?? [])
                .compactMap { $0.name }
                .filter { !$0.isEmpty }
                .map { $0.fixedFacebookEncoding }

            items.append(PostWithTags(
                record: PostRecord(
                    id: nil,
                    source: source,
                    timestamp: raw.timestamp,
                    title: fixOptional(raw.title),
                    content: content,
                    external_url: externalURL,
                    group_name: nil,
                    has_media: hasMedia
                ),
                tags: tagNames
            ))
        }

        let insertItems = items
        try await dbQueue.write { db in
            for var item in insertItems {
                try item.record.insert(db)
                guard let postId = item.record.id else { continue }
                for tagName in item.tags {
                    try db.execute(
                        sql: "INSERT INTO post_tags (post_id, name) VALUES (?, ?)",
                        arguments: [postId, tagName]
                    )
                }
            }
        }
        return insertItems.count
    }
}
