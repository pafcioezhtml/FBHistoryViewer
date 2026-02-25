import Foundation
import GRDB

struct ProfileRepository {

    func load(dbQueue: DatabaseQueue) async throws -> ProfileData {
        try await dbQueue.read { db in
            var result = ProfileData()

            // Main profile row
            if let row = try Row.fetchOne(db, sql: "SELECT * FROM profile WHERE id = 1") {
                result.name           = row["name"]           ?? ""
                result.username       = row["username"]       ?? ""
                result.aboutMe        = row["about_me"]       ?? ""
                result.birthday       = row["birthday"]       ?? ""
                result.city           = row["city"]           ?? ""
                result.hometown       = row["hometown"]       ?? ""
                result.gender         = row["gender"]         ?? ""
                result.friendsCount   = row["friends_count"]  ?? 0
                result.followersCount = row["followers_count"] ?? 0
            }

            // Work experiences
            let workRows = try Row.fetchAll(db, sql: "SELECT * FROM profile_work")
            result.workExperiences = workRows.map { row in
                WorkExperience(
                    employer: row["employer"] ?? "",
                    title:    row["title"],
                    location: row["location"],
                    period:   row["period"]
                )
            }

            // Education experiences
            let eduRows = try Row.fetchAll(db, sql: "SELECT * FROM profile_education")
            result.educationExperiences = eduRows.map { row in
                EducationExperience(
                    school:     row["school"] ?? "",
                    degree:     row["degree"],
                    field:      row["field"],
                    schoolType: row["school_type"]
                )
            }

            // Websites
            let websiteRows = try Row.fetchAll(db, sql: "SELECT address FROM profile_websites")
            result.websites = websiteRows.map { $0["address"] ?? "" }

            // Screen names
            let snRows = try Row.fetchAll(db, sql: "SELECT service, username FROM profile_screen_names")
            result.screenNames = snRows.map { (service: $0["service"] ?? "", name: $0["username"] ?? "") }

            // Family
            let familyRows = try Row.fetchAll(db, sql: "SELECT name, relation FROM profile_family")
            result.familyMembers = familyRows.map { (name: $0["name"] ?? "", relation: $0["relation"] ?? "") }

            // Profile photos — filenames stored in DB, images in app support dir
            let photosDir = DatabaseManager.profilePhotosDirectory
            let photoRows = try Row.fetchAll(db, sql: "SELECT timestamp, filename FROM profile_photos ORDER BY timestamp DESC")
            result.profilePhotos = photoRows.compactMap { row -> ProfilePhoto? in
                guard let ts: Int64 = row["timestamp"],
                      let filename: String = row["filename"] else { return nil }
                let url = photosDir.appendingPathComponent(filename)
                guard FileManager.default.fileExists(atPath: url.path) else { return nil }
                return ProfilePhoto(timestamp: ts, imageURL: url)
            }

            return result
        }
    }
}
