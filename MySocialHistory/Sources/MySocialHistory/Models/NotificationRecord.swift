import GRDB

struct NotificationRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    static let databaseTableName = "notifications"

    var id: Int64?
    var timestamp: Int64      // unix seconds
    var text: String
    var href: String
    var unread: Bool

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
