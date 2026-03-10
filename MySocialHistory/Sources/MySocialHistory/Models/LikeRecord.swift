import GRDB

struct LikeRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = TableName.likes

    var id: Int64?
    var timestamp: Int64
    var title: String
    var reaction_type: String   // LIKE|LOVE|HAHA|WOW|SAD|ANGRY

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
