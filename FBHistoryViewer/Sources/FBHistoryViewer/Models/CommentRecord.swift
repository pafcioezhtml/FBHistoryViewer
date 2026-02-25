import GRDB

struct CommentRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = TableName.comments

    var id: Int64?
    var timestamp: Int64
    var title: String?
    var comment_text: String?

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
