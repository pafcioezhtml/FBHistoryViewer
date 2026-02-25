import GRDB

struct MessageRecord: Codable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = TableName.messages

    var id: Int64?
    var thread_id: Int64
    var sender_name: String
    var timestamp_ms: Int64
    var content: String?
    var has_photos: Bool
    var has_videos: Bool
    var has_audio: Bool
    var has_gifs: Bool
    var has_files: Bool
    var has_share: Bool
    var share_url: String?
    var reaction_count: Int

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}
