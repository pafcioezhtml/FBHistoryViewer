import GRDB

struct SearchRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    static let databaseTableName = "searches"

    var id: Int64?
    var timestamp: Int64          // unix seconds
    var query: String
    var title: String             // "You searched Facebook", "You visited on Facebook", etc.

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
