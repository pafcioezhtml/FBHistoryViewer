import GRDB

struct VisitRecord: Codable, FetchableRecord, MutablePersistableRecord, Identifiable {
    static let databaseTableName = "visits"

    var id: Int64?
    var timestamp: Int64          // unix seconds (0 for marketplace entries without timestamp)
    var name: String
    var uri: String
    var category: String          // profiles, pages, events, groups, marketplace

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}

enum VisitCategory: String, CaseIterable, Identifiable {
    case events = "events"
    case groups = "groups"
    case profiles = "profiles"
    case pages = "pages"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .events:      return "Events"
        case .groups:      return "Groups"
        case .profiles:    return "Profiles"
        case .pages:       return "Pages"
        }
    }

    var icon: String {
        switch self {
        case .events:      return "calendar"
        case .groups:      return "person.3"
        case .profiles:    return "person.circle"
        case .pages:       return "flag"
        }
    }

    var color: SwiftUI.Color {
        switch self {
        case .events:      return .orange
        case .groups:      return .teal
        case .profiles:    return .blue
        case .pages:       return .purple
        }
    }
}

import SwiftUI
