import Foundation
import GRDB

actor LikeImporter {
    private let dbQueue: DatabaseQueue
    private let decoder = JSONDecoder()

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    func importAll(reactionsDirectory: URL) async throws -> Int {
        guard FileManager.default.fileExists(atPath: reactionsDirectory.path) else { return 0 }

        let allFiles = (try? FileManager.default.contentsOfDirectory(
            at: reactionsDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []

        // Collect all records from every file first, then deduplicate by timestamp
        // (likes_and_reactions.json is often a subset of the numbered files)
        var allRecords: [LikeRecord] = []

        // Numbered files: likes_and_reactions_1.json … (structured format)
        let numbered = allFiles
            .filter {
                let name = $0.lastPathComponent
                return name.hasPrefix("likes_and_reactions_") &&
                       name != "likes_and_reactions.json" &&
                       $0.pathExtension == "json"
            }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        for f in numbered { allRecords.append(contentsOf: try decodeNumberedFile(f)) }

        // Non-numbered file: label_values format
        let labelFile = reactionsDirectory.appendingPathComponent("likes_and_reactions.json")
        if FileManager.default.fileExists(atPath: labelFile.path) {
            allRecords.append(contentsOf: try decodeLabelFile(labelFile))
        }

        // Deduplicate by timestamp — the same like can appear in both file formats
        var seen = Set<Int64>()
        let deduped = allRecords.filter { seen.insert($0.timestamp).inserted }

        try await dbQueue.write { db in
            for var r in deduped { try r.insert(db) }
        }
        return deduped.count
    }

    private func decodeNumberedFile(_ fileURL: URL) throws -> [LikeRecord] {
        let data = try Data(contentsOf: fileURL)
        let items = try decoder.decode([RawLikeItem].self, from: data)
        return items.compactMap { item in
            guard let rd = item.data?.first?.reaction else { return nil }
            return LikeRecord(
                id: nil,
                timestamp: item.timestamp,
                title: item.title?.fixedFacebookEncoding ?? rd.actor.fixedFacebookEncoding,
                reaction_type: rd.reaction.uppercased()
            )
        }
    }

    private func decodeLabelFile(_ fileURL: URL) throws -> [LikeRecord] {
        let data = try Data(contentsOf: fileURL)
        let items = try decoder.decode([RawLikeLabelItem].self, from: data)
        return items.compactMap { item in
            guard let lv = item.label_values, !lv.isEmpty else { return nil }
            let reaction = lv.first { $0.label == "Reaction" }?.value ?? "LIKE"
            let name     = lv.first { $0.label == "Name" }?.value ?? ""
            return LikeRecord(
                id: nil,
                timestamp: item.timestamp,
                title: name.fixedFacebookEncoding,
                reaction_type: reaction.uppercased()
            )
        }
    }
}
