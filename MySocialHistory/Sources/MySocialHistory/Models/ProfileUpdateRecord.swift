import GRDB

struct ProfileUpdateRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    static let databaseTableName = "profile_updates"

    var id: Int64?
    var timestamp: Int64      // unix seconds
    var title: String
    var detail: String?       // bio text, website URL, screen name, etc.
    var image_uri: String?    // relative path to profile picture (if applicable)

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
