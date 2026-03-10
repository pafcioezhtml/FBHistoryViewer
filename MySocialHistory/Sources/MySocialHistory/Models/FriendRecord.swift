import GRDB

struct FriendRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "friends"

    var id: Int64?
    var name: String
    var timestamp: Int64          // unix seconds
    var status: String            // "current" or "removed"

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
