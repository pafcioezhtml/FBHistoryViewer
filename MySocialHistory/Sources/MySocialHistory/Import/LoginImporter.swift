import Foundation
import GRDB

actor LoginImporter {
    private let dbQueue: DatabaseQueue
    private let decoder = JSONDecoder()

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Imports login/session activity from `security_and_login_information/account_activity.json`.
    /// Returns total number of records imported.
    func importAll(exportParent: URL) async throws -> Int {
        let filePath = exportParent
            .appendingPathComponent("security_and_login_information")
            .appendingPathComponent("account_activity.json")

        guard FileManager.default.fileExists(atPath: filePath.path),
              let data = try? Data(contentsOf: filePath),
              let file = try? decoder.decode(RawAccountActivityFile.self, from: data)
        else { return 0 }

        var records: [LoginRecord] = []
        for entry in file.account_activity_v2 ?? [] {
            let ua = entry.user_agent ?? ""
            records.append(LoginRecord(
                id: nil,
                timestamp: Int64(entry.timestamp),
                action: entry.action ?? "Unknown",
                ip_address: entry.ip_address ?? "",
                user_agent: ua,
                city: (entry.city ?? "").fixedFacebookEncoding,
                region: (entry.region ?? "").fixedFacebookEncoding,
                country: entry.country ?? "",
                device_type: classifyDevice(ua)
            ))
        }

        guard !records.isEmpty else { return 0 }

        let insertRecords = records
        try await dbQueue.write { db in
            for var r in insertRecords { try r.insert(db) }
        }
        return records.count
    }

    private func classifyDevice(_ ua: String) -> String {
        if ua.contains("iPhone") { return "iPhone" }
        if ua.contains("iPad") { return "iPad" }
        if ua.contains("Android") { return "Android" }
        if ua.contains("Macintosh") || ua.contains("Mac OS") { return "Mac" }
        if ua.contains("Windows") { return "Windows" }
        if ua.contains("Linux") { return "Linux" }
        return "Other"
    }
}

// MARK: - Raw JSON

private struct RawAccountActivityFile: Decodable {
    let account_activity_v2: [RawAccountActivity]?
}

private struct RawAccountActivity: Decodable {
    let action: String?
    let timestamp: Int
    let ip_address: String?
    let user_agent: String?
    let city: String?
    let region: String?
    let country: String?
}
