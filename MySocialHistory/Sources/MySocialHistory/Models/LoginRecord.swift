import GRDB

struct LoginRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "logins"

    var id: Int64?
    var timestamp: Int64          // unix seconds
    var action: String            // "Login", "Session updated", etc.
    var ip_address: String
    var user_agent: String
    var city: String
    var region: String
    var country: String
    var device_type: String       // "iPhone", "iPad", "Mac", "Windows", "Android", "Other"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
