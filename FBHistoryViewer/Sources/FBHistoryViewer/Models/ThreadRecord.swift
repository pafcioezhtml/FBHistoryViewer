import GRDB

struct ThreadRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = TableName.threads

    var id: Int64?
    var thread_slug: String
    var thread_path: String
    var category: String
    var title: String
    var is_group_chat: Bool
    var participant_names: String   // JSON-encoded [String]
    var message_count: Int
    var first_message_at: Int64?
    var last_message_at: Int64?

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
