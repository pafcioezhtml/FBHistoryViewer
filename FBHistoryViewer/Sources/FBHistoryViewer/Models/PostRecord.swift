import GRDB

struct PostRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = TableName.posts

    var id: Int64?
    var source: String        // "timeline" or "group"
    var timestamp: Int64
    var title: String?
    var content: String?
    var external_url: String?
    var group_name: String?
    var has_media: Bool

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
