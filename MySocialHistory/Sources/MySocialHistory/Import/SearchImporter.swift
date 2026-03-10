import Foundation
import GRDB

actor SearchImporter {
    private let dbQueue: DatabaseQueue
    private let decoder = JSONDecoder()

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Imports search history from `logged_information/search/your_search_history.json`.
    func importAll(exportParent: URL) async throws -> Int {
        let filePath = exportParent
            .appendingPathComponent("logged_information")
            .appendingPathComponent("search")
            .appendingPathComponent("your_search_history.json")

        guard FileManager.default.fileExists(atPath: filePath.path),
              let data = try? Data(contentsOf: filePath),
              let file = try? decoder.decode(RawSearchFile.self, from: data)
        else { return 0 }

        var records: [SearchRecord] = []
        for entry in file.searches_v2 ?? [] {
            let query = entry.data?.first?.text ?? ""
            guard !query.isEmpty else { continue }
            records.append(SearchRecord(
                id: nil,
                timestamp: Int64(entry.timestamp),
                query: query.fixedFacebookEncoding,
                title: (entry.title ?? "").fixedFacebookEncoding
            ))
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

private struct RawSearchFile: Decodable {
    let searches_v2: [RawSearchEntry]?
}

private struct RawSearchEntry: Decodable {
    let timestamp: Int
    let data: [RawSearchData]?
    let title: String?
}

private struct RawSearchData: Decodable {
    let text: String?
}
