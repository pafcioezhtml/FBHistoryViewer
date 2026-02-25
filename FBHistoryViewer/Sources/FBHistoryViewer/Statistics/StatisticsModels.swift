import Foundation

struct OverviewStats {
    var threadCount: Int = 0
    var messageCount: Int = 0
    var postCount: Int = 0
    var likeCount: Int = 0
    var commentCount: Int = 0
    var reactionCount: Int = 0
}

struct PostTypeStats {
    var ownPosts: Int = 0
    var wallPosts: Int = 0
    var groupPosts: Int = 0
    var total: Int { ownPosts + wallPosts + groupPosts }
}

struct ReactionTypeStats {
    var likeCount: Int = 0
    var loveCount: Int = 0
    var hahaCount: Int = 0
    var wowCount: Int = 0
    var sadCount: Int = 0
    var angryCount: Int = 0
    var total: Int { likeCount + loveCount + hahaCount + wowCount + sadCount + angryCount }
}

struct MonthCount: Identifiable {
    var id: String { month }
    let month: String      // "YYYY-MM"
    let count: Int
    var date: Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.date(from: month) ?? Date()
    }
}

struct PostYearBreakdown: Identifiable {
    var id: String { year }
    let year: String
    let ownPosts: Int
    let wallPosts: Int
    let groupPosts: Int
    var total: Int { ownPosts + wallPosts + groupPosts }
}

struct ThreadStat: Identifiable {
    var id: Int64 { threadId }
    let threadId: Int64
    let title: String
    let messageCount: Int       // total messages in thread
    let myMessageCount: Int     // messages sent by the current user
    let isGroupChat: Bool
    let participantNames: [String]
    let firstMessageAt: Int64?   // unix ms
    let mostActiveYear: String?

    var firstExchangeDate: Date? {
        guard let ts = firstMessageAt, ts > 0 else { return nil }
        return Date(timeIntervalSince1970: Double(ts) / 1000.0)
    }
}

struct HourCount: Identifiable {
    var id: Int { hour }
    let hour: Int     // 0–23
    let count: Int
}

struct WeekdayCount: Identifiable {
    var id: Int { weekday }
    let weekday: Int   // 0 = Sunday … 6 = Saturday (SQLite strftime %w)
    let count: Int
    var displayName: String {
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[safe: weekday] ?? "\(weekday)"
    }
}

struct ReactionCount: Identifiable {
    var id: String { emoji }
    let emoji: String
    let count: Int
}

struct DayCount: Identifiable {
    var id: Int64 { dayKey }
    let dayKey: Int64    // timestamp_ms / 86400000
    let count: Int
    var date: Date { Date(timeIntervalSince1970: Double(dayKey) * 86400) }
}

struct YearAverage: Identifiable {
    var id: String { year }
    let year: String
    let value: Double
}

struct CommentEngagement: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
}

struct ReactionEngagement: Identifiable {
    var id: String { name }
    let name: String
    let total: Int
    let likeCount: Int
    let loveCount: Int
    let hahaCount: Int
    let wowCount: Int
    let sadCount: Int
    let angryCount: Int

    var breakdown: [(emoji: String, count: Int)] {
        [("👍", likeCount), ("❤️", loveCount), ("😆", hahaCount),
         ("😮", wowCount), ("😢", sadCount), ("😡", angryCount)]
            .filter { $0.count > 0 }
    }
}

struct TaggedPerson: Identifiable {
    var id: String { name }
    let name: String
    let count: Int
}

struct SharedDomain: Identifiable {
    var id: String { domain }
    let domain: String
    let count: Int
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
