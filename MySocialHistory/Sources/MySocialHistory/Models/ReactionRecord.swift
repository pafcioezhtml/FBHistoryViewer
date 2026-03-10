import GRDB

struct ReactionRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = TableName.reactions

    var id: Int64?
    var message_id: Int64
    var reaction_emoji: String
    var actor_name: String

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
