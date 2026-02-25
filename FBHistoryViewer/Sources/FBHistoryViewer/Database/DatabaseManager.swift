import Foundation
import GRDB

final class DatabaseManager {
    static let shared: DatabaseManager = {
        do {
            return try DatabaseManager()
        } catch {
            fatalError("Cannot open database: \(error)")
        }
    }()

    let dbQueue: DatabaseQueue

    private init() throws {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dbDir = appSupport.appendingPathComponent("FBHistoryViewer")
        try FileManager.default.createDirectory(at: dbDir, withIntermediateDirectories: true)
        let dbPath = dbDir.appendingPathComponent("history.sqlite").path

        var config = Configuration()
        config.maximumReaderCount = 5
        dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

        try Migrations.registerMigrations(dbQueue)
    }

    static var profilePhotosDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = appSupport
            .appendingPathComponent("FBHistoryViewer")
            .appendingPathComponent("profile_photos")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func eraseDatabase() throws {
        try dbQueue.erase()
        try Migrations.registerMigrations(dbQueue)
        // Clear copied profile photos
        let photosDir = DatabaseManager.profilePhotosDirectory
        if let files = try? FileManager.default.contentsOfDirectory(
            at: photosDir, includingPropertiesForKeys: nil
        ) {
            for file in files { try? FileManager.default.removeItem(at: file) }
        }
    }
}
