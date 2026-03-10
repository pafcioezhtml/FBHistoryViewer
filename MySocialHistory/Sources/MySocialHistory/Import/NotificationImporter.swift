import Foundation
import GRDB

actor NotificationImporter {
    private let dbQueue: DatabaseQueue
    private let decoder = JSONDecoder()

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Imports notifications from `logged_information/notifications/notifications.json`.
    func importAll(exportParent: URL) async throws -> Int {
        let filePath = exportParent
            .appendingPathComponent("logged_information")
            .appendingPathComponent("notifications")
            .appendingPathComponent("notifications.json")

        guard FileManager.default.fileExists(atPath: filePath.path),
              let data = try? Data(contentsOf: filePath),
              let file = try? decoder.decode(RawNotificationsFile.self, from: data)
        else { return 0 }

        var records: [NotificationRecord] = []
        for entry in file.notifications_v2 ?? [] {
            let text = (entry.text ?? "").fixedFacebookEncoding
            guard !text.isEmpty else { continue }
            records.append(NotificationRecord(
                id: nil,
                timestamp: Int64(entry.timestamp),
                text: text,
                href: entry.href ?? "",
                unread: entry.unread ?? false
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

private struct RawNotificationsFile: Decodable {
    let notifications_v2: [RawNotification]?
}

private struct RawNotification: Decodable {
    let timestamp: Int
    let text: String?
    let href: String?
    let unread: Bool?
}
