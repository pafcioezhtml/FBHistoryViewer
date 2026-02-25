import Foundation
import GRDB

struct MessageImporterProgress {
    var completed: Int
    var currentName: String
    var addedMessages: Int
    var errors: Int
}

/// Each "thread group" is all the directories across multiple exports that share
/// the same slug.  We merge their message files and deduplicate by timestamp_ms.
typealias ThreadGroup = [(url: URL, category: String)]

actor MessageImporter {
    private let dbQueue: DatabaseQueue
    private let decoder = JSONDecoder()

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func importAll(
        threadGroups: [ThreadGroup],
        progress: @escaping @Sendable (MessageImporterProgress) -> Void
    ) async throws {
        var completed = 0
        let batchSize = 8
        var index = 0

        while index < threadGroups.count {
            try Task.checkCancellation()
            let batch = Array(threadGroups[index..<min(index + batchSize, threadGroups.count)])
            index += batchSize

            try await withThrowingTaskGroup(of: Int.self) { group in
                for dirs in batch {
                    group.addTask {
                        try await self.importThreadGroup(dirs: dirs)
                    }
                }
                for try await added in group {
                    completed += 1
                    progress(MessageImporterProgress(
                        completed: completed,
                        currentName: "",
                        addedMessages: added,
                        errors: 0
                    ))
                }
            }
        }
    }

    // MARK: - Single thread group (same slug, potentially multiple export dirs)

    private func importThreadGroup(dirs: ThreadGroup) async throws -> Int {
        guard let first = dirs.first else { return 0 }
        let slug     = first.url.lastPathComponent
        let category = first.category   // use category from first occurrence

        // Collect all message files from every directory in the group
        var allMessages: [RawMessage] = []
        var title        = ""
        var participants: [String] = []
        var threadPath   = ""
        var metadataSet  = false

        for entry in dirs {
            let files = messageFiles(in: entry.url)
            for (i, fileURL) in files.enumerated() {
                guard let data = try? Data(contentsOf: fileURL),
                      let file = try? decoder.decode(RawMessageFile.self, from: data) else { continue }
                allMessages.append(contentsOf: file.messages)
                if !metadataSet || i == 0 {
                    // Use metadata from the first file of the first dir that has a real title
                    if !file.title.isEmpty { title = file.title.fixedFacebookEncoding }
                    if !file.participants.isEmpty {
                        participants = file.participants.map { $0.name.fixedFacebookEncoding }
                    }
                    threadPath = file.thread_path
                    metadataSet = true
                }
            }
        }

        guard !allMessages.isEmpty else { return 0 }

        // Deduplicate by timestamp_ms — same message can appear in multiple exports
        // (a thread covering 2020-2024 is present in both a 2022 and a 2024 export)
        var seen = Set<Int64>()
        let deduped = allMessages.filter { seen.insert($0.timestamp_ms).inserted }
        let sorted  = deduped.sorted { $0.timestamp_ms < $1.timestamp_ms }

        let firstTs    = sorted.first?.timestamp_ms
        let lastTs     = sorted.last?.timestamp_ms
        let isGroup    = participants.count > 2
        let pNamesJSON = encodeParticipantNames(participants)

        // Capture only let-values for the @Sendable closure
        let slug_       = slug
        let threadPath_ = threadPath
        let category_   = category
        let title_      = title
        let isGroup_    = isGroup
        let pNamesJSON_ = pNamesJSON
        let firstTs_    = firstTs
        let lastTs_     = lastTs
        let sorted_     = sorted
        let msgCount    = sorted.count

        let insertedCount = try await dbQueue.write { db -> Int in
            var thread = ThreadRecord(
                id: nil,
                thread_slug: slug_,
                thread_path: threadPath_,
                category: category_,
                title: title_,
                is_group_chat: isGroup_,
                participant_names: pNamesJSON_,
                message_count: msgCount,
                first_message_at: firstTs_,
                last_message_at: lastTs_
            )
            if let existing = try ThreadRecord.filter(Column("thread_slug") == slug_).fetchOne(db) {
                thread.id = existing.id
                try thread.update(db)
            } else {
                try thread.insert(db)
            }
            guard let threadId = thread.id else { return 0 }

            var count = 0
            for raw in sorted_ {
                var msg = MessageRecord(
                    id: nil,
                    thread_id: threadId,
                    sender_name: raw.sender_name.fixedFacebookEncoding,
                    timestamp_ms: raw.timestamp_ms,
                    content: fixOptional(raw.content),
                    has_photos: !(raw.photos?.isEmpty ?? true),
                    has_videos: !(raw.videos?.isEmpty ?? true),
                    has_audio: !(raw.audio_files?.isEmpty ?? true),
                    has_gifs: !(raw.gifs?.isEmpty ?? true),
                    has_files: !(raw.files?.isEmpty ?? true),
                    has_share: raw.share != nil,
                    share_url: raw.share?.link,
                    reaction_count: raw.reactions?.count ?? 0
                )
                try msg.insert(db)
                count += 1

                if let msgId = msg.id, let reactions = raw.reactions, !reactions.isEmpty {
                    for r in reactions {
                        var reaction = ReactionRecord(
                            id: nil,
                            message_id: msgId,
                            reaction_emoji: r.reaction.fixedFacebookEncoding,
                            actor_name: r.actor.fixedFacebookEncoding
                        )
                        try reaction.insert(db)
                    }
                }
            }
            return count
        }

        return insertedCount
    }

    // MARK: - Helpers

    private func messageFiles(in threadURL: URL) -> [URL] {
        var files: [URL] = []
        var page = 1
        while FileManager.default.fileExists(
            atPath: threadURL.appendingPathComponent("message_\(page).json").path
        ) {
            files.append(threadURL.appendingPathComponent("message_\(page).json"))
            page += 1
        }
        return files
    }

    private func encodeParticipantNames(_ names: [String]) -> String {
        let data = (try? JSONEncoder().encode(names)) ?? Data()
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}
