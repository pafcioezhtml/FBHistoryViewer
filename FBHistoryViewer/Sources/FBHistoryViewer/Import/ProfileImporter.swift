import Foundation
import GRDB

actor ProfileImporter {
    private let dbQueue: DatabaseQueue

    init(dbQueue: DatabaseQueue) {
        self.dbQueue = dbQueue
    }

    /// Imports profile data from a Facebook export root.
    /// `activityRoot` is the `your_facebook_activity/` folder; profile data lives
    /// in `personal_information/` and `connections/` which are siblings of it.
    func importProfile(activityRoot: URL) async throws {
        let exportParent = activityRoot.deletingLastPathComponent()

        let profileInfoURL = exportParent
            .appendingPathComponent("personal_information")
            .appendingPathComponent("profile_information")
            .appendingPathComponent("profile_information.json")

        guard FileManager.default.fileExists(atPath: profileInfoURL.path),
              let data = try? Data(contentsOf: profileInfoURL),
              let profileFile = try? JSONDecoder().decode(RawProfileFile.self, from: data)
        else { return }

        let p = profileFile.profile_v2

        let name     = p.name?.full_name?.fixedFacebookEncoding ?? ""
        let username = p.username?.fixedFacebookEncoding ?? ""
        let aboutMe  = p.about_me?.fixedFacebookEncoding ?? ""
        let birthday = formatBirthday(month: p.birthday?.month, day: p.birthday?.day, year: p.birthday?.year)
        let city     = p.current_city?.name?.fixedFacebookEncoding ?? ""
        let hometown = p.hometown?.name?.fixedFacebookEncoding ?? ""
        let gender   = formatGender(p.gender?.gender_option)

        let friendsURL = exportParent
            .appendingPathComponent("connections")
            .appendingPathComponent("friends")
            .appendingPathComponent("your_friends.json")
        let friendsCount = countItems(RawFriends.self, keyPath: \.friends_v2, at: friendsURL)

        let followersURL = exportParent
            .appendingPathComponent("connections")
            .appendingPathComponent("followers")
            .appendingPathComponent("people_who_followed_you.json")
        let followersCount = countItems(RawFollowers.self, keyPath: \.followers_v3, at: followersURL)

        let workRows = (p.work_experiences ?? []).map { raw in (
            employer: raw.employer?.fixedFacebookEncoding ?? "",
            title:    raw.title?.fixedFacebookEncoding,
            location: raw.location?.fixedFacebookEncoding,
            period:   formatWorkPeriod(start: raw.start_timestamp, end: raw.end_timestamp)
        )}

        let eduRows = (p.education_experiences ?? []).map { raw in (
            school:     raw.name?.fixedFacebookEncoding ?? "",
            degree:     raw.degree?.fixedFacebookEncoding,
            field:      raw.concentrations?.first?.fixedFacebookEncoding,
            schoolType: raw.school_type?.fixedFacebookEncoding
        )}

        let websites = (p.websites ?? []).compactMap { $0.address?.fixedFacebookEncoding }

        let screenNames = (p.screen_names ?? []).compactMap { sn -> (service: String, username: String)? in
            guard let service = sn.service_name?.fixedFacebookEncoding,
                  let uname  = sn.names?.first?.name?.fixedFacebookEncoding else { return nil }
            return (service: service, username: uname)
        }

        let family = (p.family_members ?? []).compactMap { fm -> (name: String, relation: String)? in
            guard let name     = fm.name?.fixedFacebookEncoding,
                  let relation = fm.relation?.fixedFacebookEncoding else { return nil }
            return (name: name, relation: relation)
        }

        // Collect profile photos, copy to app support, record filenames
        let photoRows = collectPhotos(exportParent: exportParent)

        try await dbQueue.write { db in
            try db.execute(
                sql: """
                    INSERT OR REPLACE INTO profile
                        (id, name, username, about_me, birthday, city, hometown, gender,
                         friends_count, followers_count)
                    VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                arguments: [name, username, aboutMe, birthday, city, hometown, gender,
                            friendsCount, followersCount]
            )

            try db.execute(sql: "DELETE FROM profile_work")
            for w in workRows {
                try db.execute(
                    sql: "INSERT INTO profile_work (employer, title, location, period) VALUES (?, ?, ?, ?)",
                    arguments: [w.employer, w.title, w.location, w.period]
                )
            }

            try db.execute(sql: "DELETE FROM profile_education")
            for e in eduRows {
                try db.execute(
                    sql: "INSERT INTO profile_education (school, degree, field, school_type) VALUES (?, ?, ?, ?)",
                    arguments: [e.school, e.degree, e.field, e.schoolType]
                )
            }

            try db.execute(sql: "DELETE FROM profile_websites")
            for w in websites {
                try db.execute(sql: "INSERT INTO profile_websites (address) VALUES (?)", arguments: [w])
            }

            try db.execute(sql: "DELETE FROM profile_screen_names")
            for sn in screenNames {
                try db.execute(
                    sql: "INSERT INTO profile_screen_names (service, username) VALUES (?, ?)",
                    arguments: [sn.service, sn.username]
                )
            }

            try db.execute(sql: "DELETE FROM profile_family")
            for fm in family {
                try db.execute(
                    sql: "INSERT INTO profile_family (name, relation) VALUES (?, ?)",
                    arguments: [fm.name, fm.relation]
                )
            }

            try db.execute(sql: "DELETE FROM profile_photos")
            for ph in photoRows {
                try db.execute(
                    sql: "INSERT INTO profile_photos (timestamp, filename) VALUES (?, ?)",
                    arguments: [ph.timestamp, ph.filename]
                )
            }
        }
    }

    // MARK: - Photo collection

    private func collectPhotos(exportParent: URL) -> [(timestamp: Int64, filename: String)] {
        let updateHistoryURL = exportParent
            .appendingPathComponent("personal_information")
            .appendingPathComponent("profile_information")
            .appendingPathComponent("profile_update_history.json")

        guard let histData = try? Data(contentsOf: updateHistoryURL),
              let history  = try? JSONDecoder().decode(RawProfileUpdateHistory.self, from: histData)
        else { return [] }

        let photosDir = DatabaseManager.profilePhotosDirectory
        var seen   = Set<Int64>()
        var result: [(timestamp: Int64, filename: String)] = []

        for update in history.profile_updates_v2 ?? [] {
            for attachment in update.attachments ?? [] {
                for datum in attachment.data ?? [] {
                    guard let media = datum.media, let uri = media.uri else { continue }
                    let timestamp = media.creation_timestamp ?? update.timestamp ?? 0
                    guard seen.insert(timestamp).inserted else { continue }

                    let sourceURL = exportParent.appendingPathComponent(uri)
                    guard FileManager.default.fileExists(atPath: sourceURL.path) else { continue }

                    let ext      = sourceURL.pathExtension.isEmpty ? "jpg" : sourceURL.pathExtension
                    let filename = "\(timestamp).\(ext)"
                    let destURL  = photosDir.appendingPathComponent(filename)

                    if !FileManager.default.fileExists(atPath: destURL.path) {
                        try? FileManager.default.copyItem(at: sourceURL, to: destURL)
                    }
                    result.append((timestamp: timestamp, filename: filename))
                }
            }
        }

        result.sort { $0.timestamp > $1.timestamp }
        return result
    }

    // MARK: - Helpers

    private func countItems<T: Decodable, U>(_ type: T.Type, keyPath: KeyPath<T, [U]?>, at url: URL) -> Int {
        guard let data    = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(type, from: data) else { return 0 }
        return decoded[keyPath: keyPath]?.count ?? 0
    }

    private func formatBirthday(month: Int?, day: Int?, year: Int?) -> String {
        var components = DateComponents()
        components.month = month
        components.day   = day
        components.year  = year
        if let date = Calendar.current.date(from: components) {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM d, yyyy"
            return fmt.string(from: date)
        }
        if let m = month, let d = day, let y = year {
            return "\(monthName(m)) \(d), \(y)"
        }
        return ""
    }

    private func monthName(_ m: Int) -> String {
        let names = ["January","February","March","April","May","June",
                     "July","August","September","October","November","December"]
        return (1...12).contains(m) ? names[m - 1] : "\(m)"
    }

    private func formatGender(_ raw: String?) -> String {
        switch raw?.uppercased() {
        case "MALE":   return "Male"
        case "FEMALE": return "Female"
        default:       return raw?.fixedFacebookEncoding ?? ""
        }
    }

    private func formatWorkPeriod(start: Int64?, end: Int64?) -> String? {
        let cal = Calendar.current
        var parts: [String] = []
        if let s = start, s > 0 {
            parts.append("\(cal.component(.year, from: Date(timeIntervalSince1970: Double(s))))")
        }
        if let e = end, e > 0 {
            parts.append("\(cal.component(.year, from: Date(timeIntervalSince1970: Double(e))))")
        } else if !parts.isEmpty {
            parts.append("present")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " – ")
    }
}

// MARK: - Raw JSON structs (private to this file)

private struct RawProfileFile: Decodable {
    let profile_v2: RawProfile
}

private struct RawProfile: Decodable {
    let name:                RawProfileName?
    let birthday:            RawBirthday?
    let gender:              RawGender?
    let current_city:        RawNamedPlace?
    let hometown:            RawNamedPlace?
    let family_members:      [RawFamilyMember]?
    let education_experiences: [RawEducation]?
    let work_experiences:    [RawWork]?
    let websites:            [RawWebsite]?
    let screen_names:        [RawScreenName]?
    let username:            String?
    let about_me:            String?
}

private struct RawProfileName: Decodable {
    let full_name: String?
}

private struct RawBirthday: Decodable {
    let year: Int?; let month: Int?; let day: Int?
}

private struct RawGender: Decodable {
    let gender_option: String?
}

private struct RawNamedPlace: Decodable {
    let name: String?
}

private struct RawFamilyMember: Decodable {
    let name: String?; let relation: String?
}

private struct RawEducation: Decodable {
    let name: String?
    let concentrations: [String]?
    let degree: String?
    let school_type: String?
}

private struct RawWork: Decodable {
    let employer: String?
    let title: String?
    let location: String?
    let start_timestamp: Int64?
    let end_timestamp: Int64?
}

private struct RawWebsite: Decodable {
    let address: String?
}

private struct RawScreenName: Decodable {
    let service_name: String?
    let names: [RawScreenNameEntry]?
}

private struct RawScreenNameEntry: Decodable {
    let name: String?
}

private struct RawProfileUpdateHistory: Decodable {
    let profile_updates_v2: [RawProfileUpdate]?
}

private struct RawProfileUpdate: Decodable {
    let timestamp: Int64?
    let attachments: [RawUpdateAttachment]?
}

private struct RawUpdateAttachment: Decodable {
    let data: [RawUpdateAttachmentData]?
}

private struct RawUpdateAttachmentData: Decodable {
    let media: RawUpdateMedia?
}

private struct RawUpdateMedia: Decodable {
    let uri: String?
    let creation_timestamp: Int64?
}

private struct RawFriends: Decodable {
    let friends_v2: [RawFriendEntry]?
}

private struct RawFriendEntry: Decodable {
    let name: String?
}

private struct RawFollowers: Decodable {
    let followers_v3: [RawFollowerEntry]?
}

private struct RawFollowerEntry: Decodable {
    let name: String?
}
