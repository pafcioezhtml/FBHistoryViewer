import Foundation
import GRDB

actor VisitImporter {
    private let dbQueue: DatabaseQueue
    private let decoder = JSONDecoder()

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Imports visit history from `logged_information/interactions/recently_visited.json`.
    func importAll(exportParent: URL) async throws -> Int {
        let filePath = exportParent
            .appendingPathComponent("logged_information")
            .appendingPathComponent("interactions")
            .appendingPathComponent("recently_visited.json")

        guard FileManager.default.fileExists(atPath: filePath.path),
              let data = try? Data(contentsOf: filePath),
              let file = try? decoder.decode(RawVisitedFile.self, from: data)
        else { return 0 }

        var records: [VisitRecord] = []

        for category in file.visited_things_v2 ?? [] {
            let cat = mapCategory(category.name ?? "")
            guard !cat.isEmpty else { continue }

            for entry in category.entries ?? [] {
                let name = (entry.data?.name ?? entry.data?.value ?? "").fixedFacebookEncoding
                guard !name.isEmpty else { continue }
                let uri = entry.data?.uri ?? ""
                let timestamp = entry.timestamp ?? 0

                records.append(VisitRecord(
                    id: nil,
                    timestamp: Int64(timestamp),
                    name: name,
                    uri: uri,
                    category: cat
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

    private func mapCategory(_ name: String) -> String {
        let n = name.lowercased()
        if n.contains("profile") { return "profiles" }
        if n.contains("page") { return "pages" }
        if n.contains("event") { return "events" }
        if n.contains("group") { return "groups" }
        return ""
    }
}

// MARK: - Raw JSON

private struct RawVisitedFile: Decodable {
    let visited_things_v2: [RawVisitCategory]?
}

private struct RawVisitCategory: Decodable {
    let name: String?
    let entries: [RawVisitEntry]?
}

private struct RawVisitEntry: Decodable {
    let timestamp: Int?
    let data: RawVisitData?
}

private struct RawVisitData: Decodable {
    let name: String?
    let uri: String?
    let value: String?    // marketplace entries use value instead of name
}
